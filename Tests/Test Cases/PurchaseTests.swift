import XCTest
import Foundation
import StoreKit
@testable import MerchantKit

class PurchaseTests : XCTestCase {
    func testMatchingSubscriptionPeriod() {
        guard #available(iOS 11.2, *) else { return }
        
        let expectations: [(SKProduct.PeriodUnit, SubscriptionPeriod.Unit)] = [
            (.day, .day),
            (.week, .week),
            (.month, .month),
            (.year, .year)
        ]
        
        for subscriptionTestProduct in self.testProducts(areSubscriptions: true) {
            for (numberOfUnits, expectation) in expectations.enumerated() {
                let mockSubscriptionPeriod = MockSKProductSubscriptionPeriod(unit: expectation.0, numberOfUnits: numberOfUnits)
                let mockProduct = MockSKProductWithSubscription(productIdentifier: subscriptionTestProduct.identifier, price: NSDecimalNumber(string: "1.00"), priceLocale: .current, subscriptionPeriod: mockSubscriptionPeriod, introductoryOffer: nil)
                
                let purchase = Purchase(from: .availableProduct(mockProduct), for: subscriptionTestProduct)
                
                let terms = purchase.subscriptionTerms
                XCTAssertNotNil(terms)
                
                let isRecurring: Bool
                
                switch subscriptionTestProduct.kind {
                    case .subscription(automaticallyRenews: true): isRecurring = true
                    default: isRecurring = false
                }
                
                let period = SubscriptionPeriod(unit: expectation.1, unitCount: numberOfUnits)
                let duration = SubscriptionDuration(period: period, isRecurring: isRecurring)
                
                XCTAssertEqual(terms!.duration, duration)
            }
        }
    }
    
    func testMatchingSubscriptionIntroductoryOffer() {
        guard #available(iOS 11.2, *) else { return }
        
        let mockSubscriptionPeriod = MockSKProductSubscriptionPeriod(unit: .month, numberOfUnits: 1)
        
        let expectations: [(SKProductDiscount, SubscriptionTerms.IntroductoryOffer)] = [
            (MockSKProductDiscount(price: NSDecimalNumber(string: "1.00"), priceLocale: .current, subscriptionPeriod: mockSubscriptionPeriod, numberOfPeriods: 6, paymentMode: .payAsYouGo), SubscriptionTerms.IntroductoryOffer.recurringDiscount(discountedPrice: Price(value: (Decimal(string: "1.00")!, .current)), recurringPeriod: .months(1), discountedPeriodCount: 6)),
            (MockSKProductDiscount(price: NSDecimalNumber(string: "1.00"), priceLocale: .current, subscriptionPeriod: mockSubscriptionPeriod, numberOfPeriods: 6, paymentMode: .payUpFront), SubscriptionTerms.IntroductoryOffer.upfrontDiscount(discountedPrice: Price(value: (Decimal(string: "1.00")!, .current)), period: .months(6))),
            (MockSKProductDiscount(price: NSDecimalNumber(string: "0.00"), priceLocale: .current, subscriptionPeriod: mockSubscriptionPeriod, numberOfPeriods: 1, paymentMode: .freeTrial), SubscriptionTerms.IntroductoryOffer.freeTrial(period: .months(1)))
        ]

        for subscriptionTestProduct in self.testProducts(areSubscriptions: true) {
            for expectation in expectations {
                let mockProduct = MockSKProductWithSubscription(productIdentifier: subscriptionTestProduct.identifier, price: NSDecimalNumber(string: "1.00"), priceLocale: .current, subscriptionPeriod: mockSubscriptionPeriod, introductoryOffer: expectation.0)
                
                let purchase = Purchase(from: .availableProduct(mockProduct), for: subscriptionTestProduct)
                
                let terms = purchase.subscriptionTerms
                XCTAssertNotNil(terms)
                
                let introductoryOffer = terms!.introductoryOffer
                XCTAssertNotNil(introductoryOffer)
                
                XCTAssertEqual(introductoryOffer!, expectation.1)
            }
        }
    }
    
    func testNoSubscriptionPeriod() {
        guard #available(iOS 11.2, *) else { return }
        
        for subscriptionTestProduct in self.testProducts(areSubscriptions: true) {
            let mockProduct = MockSKProductWithSubscription(productIdentifier: subscriptionTestProduct.identifier, price: NSDecimalNumber(string: "1.00"), priceLocale: .current, subscriptionPeriod: nil, introductoryOffer: nil)
            let purchase = Purchase(from: .availableProduct(mockProduct), for: subscriptionTestProduct)
        
            XCTAssertNil(purchase.subscriptionTerms)
        }
    }
    
    func testNoSubscriptionTermsForNonSubscriptionProduct() {
        guard #available(iOS 11.2, *) else { return }
        
        for nonSubscriptionTestProduct in self.testProducts(areSubscriptions: false) {
            let mockSubscriptionPeriod = MockSKProductSubscriptionPeriod(unit: .day, numberOfUnits: 0)
            let mockProduct = MockSKProductWithSubscription(productIdentifier: nonSubscriptionTestProduct.identifier, price: NSDecimalNumber(string: "1.00"), priceLocale: .current, subscriptionPeriod: mockSubscriptionPeriod, introductoryOffer: nil)

            let purchase = Purchase(from: .availableProduct(mockProduct), for: nonSubscriptionTestProduct)

            XCTAssertNil(purchase.subscriptionTerms)
        }
    }
    
    private func testProducts(areSubscriptions: Bool) -> Set<Product> {
        let productKinds: [Product.Kind]
            
        if areSubscriptions {
            productKinds = [.subscription(automaticallyRenews: true), .subscription(automaticallyRenews: false)]
        } else {
            productKinds = [.nonConsumable, .consumable]
        }
        
        return Set(productKinds.map {
            Product(identifier: "testProduct", kind: $0)
        })
    }
}

@available (iOS 11.2, *)
private class MockSKProductWithSubscription : SKProduct {
    private let _productIdentifier: String
    private let _price: NSDecimalNumber
    private let _priceLocale: Locale
    private let _subscriptionPeriod: SKProductSubscriptionPeriod?
    private let _introductoryOffer: SKProductDiscount?
    
    init(productIdentifier: String, price: NSDecimalNumber, priceLocale: Locale, subscriptionPeriod: SKProductSubscriptionPeriod?, introductoryOffer: SKProductDiscount?) {
        self._productIdentifier = productIdentifier
        self._price = price
        self._priceLocale = priceLocale
        self._subscriptionPeriod = subscriptionPeriod
        self._introductoryOffer = introductoryOffer
    }
    
    override var productIdentifier: String {
        return self._productIdentifier
    }
    
    override var price: NSDecimalNumber {
        return self._price
    }
    
    override var priceLocale: Locale {
        return self._priceLocale
    }
    
    override var subscriptionPeriod: SKProductSubscriptionPeriod? {
        return self._subscriptionPeriod
    }
    
    override var introductoryPrice: SKProductDiscount? {
        return self._introductoryOffer
    }
}

@available(iOS 11.2, *)
private class MockSKProductSubscriptionPeriod : SKProductSubscriptionPeriod {
    private let _unit: SKProduct.PeriodUnit
    private let _numberOfUnits: Int
    
    init(unit: SKProduct.PeriodUnit, numberOfUnits: Int) {
        self._unit = unit
        self._numberOfUnits = numberOfUnits
    }
    
    override var unit: SKProduct.PeriodUnit {
        return self._unit
    }
    
    override var numberOfUnits: Int {
        return self._numberOfUnits
    }
}

@available(iOS 11.2, *)
private class MockSKProductDiscount : SKProductDiscount {
    let _price: NSDecimalNumber
    let _priceLocale: Locale!
    let _subscriptionPeriod: SKProductSubscriptionPeriod
    let _numberOfPeriods: Int
    let _paymentMode: SKProductDiscount.PaymentMode
    
    init(price: NSDecimalNumber, priceLocale: Locale!, subscriptionPeriod: SKProductSubscriptionPeriod, numberOfPeriods: Int, paymentMode: SKProductDiscount.PaymentMode) {
        self._price = price
        self._priceLocale = priceLocale
        self._subscriptionPeriod = subscriptionPeriod
        self._numberOfPeriods = numberOfPeriods
        self._paymentMode = paymentMode
    }
    
    override var price: NSDecimalNumber {
        return self._price
    }
    
    override var priceLocale: Locale {
        return self._priceLocale
    }
    
    override var subscriptionPeriod: SKProductSubscriptionPeriod {
        return self._subscriptionPeriod
    }
    
    override var numberOfPeriods: Int {
        return self._numberOfPeriods
    }
    
    override var paymentMode: SKProductDiscount.PaymentMode {
        return self._paymentMode
    }
}
