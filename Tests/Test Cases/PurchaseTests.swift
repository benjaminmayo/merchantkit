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
                
                if let terms = terms {
                    XCTAssertNotNil(terms.introductoryOffer)
                    
                    if let introductoryOffer = terms.introductoryOffer {
                        XCTAssertEqual(introductoryOffer, expectation.1)
                    }
                }
            }
        }
    }
    
    func testMatchingRetentionOffers() {
        guard #available(iOS 12.2, *) else { return }
        
        let mockSubscriptionPeriod = MockSKProductSubscriptionPeriod(unit: .month, numberOfUnits: 1)
        
        let expectations: [(SKProductDiscount, SubscriptionTerms.RetentionOffer)] = [
            (MockSKProductDiscountWithIdentifier(identifier: "identifier1", price: NSDecimalNumber(string: "1.00"), priceLocale: .current, subscriptionPeriod: mockSubscriptionPeriod, numberOfPeriods: 6, paymentMode: .payAsYouGo), SubscriptionTerms.RetentionOffer(identifier: "identifier1", discount: .recurring(discountedPrice: Price(value: (Decimal(string: "1.00")!, .current)), recurringPeriod: .months(1), discountedPeriodCount: 6))),
            (MockSKProductDiscountWithIdentifier(identifier: "identifier2", price: NSDecimalNumber(string: "1.00"), priceLocale: .current, subscriptionPeriod: mockSubscriptionPeriod, numberOfPeriods: 6, paymentMode: .payUpFront), SubscriptionTerms.RetentionOffer(identifier: "identifier2", discount: .upfront(discountedPrice: Price(value: (Decimal(string: "1.00")!, .current)), period: .months(6)))),
            (MockSKProductDiscountWithIdentifier(identifier: "identifier3", price: NSDecimalNumber(string: "0.00"), priceLocale: .current, subscriptionPeriod: mockSubscriptionPeriod, numberOfPeriods: 1, paymentMode: .freeTrial), SubscriptionTerms.RetentionOffer(identifier: "identifier3", discount: .freeTerm(period: .months(1))))
        ]
        
        for subscriptionTestProduct in self.testProducts(areSubscriptions: true) {
            let productDiscounts = expectations.map { $0.0 }
            let mockProduct = MockSKProductWithSubscription(productIdentifier: subscriptionTestProduct.identifier, price: NSDecimalNumber(string: "1.00"), priceLocale: .current, subscriptionPeriod: mockSubscriptionPeriod, introductoryOffer: nil, discounts: productDiscounts)
            
            let purchase = Purchase(from: .availableProduct(mockProduct), for: subscriptionTestProduct)
            
            let terms = purchase.subscriptionTerms
            XCTAssertNotNil(terms)
            
            if let terms = terms {
                let termsDiscounts = expectations.map { $0.1 }
                
                XCTAssertEqual(terms.availableRetentionOffers, termsDiscounts)
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
    
    func testNilIntroductoryOfferForUnknownSKProductSubscriptionPeriodUnit() {
        guard #available(iOS 11.2, *) else { return }
        
        for subscriptionTestProduct in self.testProducts(areSubscriptions: true) {
            let mockSubscriptionPeriod = MockSKProductSubscriptionPeriod(unit: SKProduct.PeriodUnit(rawValue: 95325234)! /* unknown future value */, numberOfUnits: 1)
            let introductoryOffer = MockSKProductDiscount(price: NSDecimalNumber(string: "0.00"), priceLocale: .init(identifier: "en_US"), subscriptionPeriod: mockSubscriptionPeriod, numberOfPeriods: 1, paymentMode: SKProductDiscount.PaymentMode(rawValue: 435345345)! /* unknown future case */)
            
            let mockProduct = MockSKProductWithSubscription(productIdentifier: subscriptionTestProduct.identifier, price: NSDecimalNumber(string: "1.00"), priceLocale: .current, subscriptionPeriod: mockSubscriptionPeriod, introductoryOffer: introductoryOffer)
            
            let purchase = Purchase(from: .availableProduct(mockProduct), for: subscriptionTestProduct)
            
            XCTAssertNil(purchase.subscriptionTerms)
        }
    }
    
    func testNilIntroductoryOfferForUnknownSKPaymentMode() {
        guard #available(iOS 11.2, *) else { return }
        
        for subscriptionTestProduct in self.testProducts(areSubscriptions: true) {
            let mockSubscriptionPeriod = MockSKProductSubscriptionPeriod(unit: .day, numberOfUnits: 1)
            let introductoryOffer = MockSKProductDiscount(price: NSDecimalNumber(string: "0.00"), priceLocale: .init(identifier: "en_US"), subscriptionPeriod: mockSubscriptionPeriod, numberOfPeriods: 1, paymentMode: SKProductDiscount.PaymentMode(rawValue: 435345345)! /* unknown future case */)
            
            let mockProduct = MockSKProductWithSubscription(productIdentifier: subscriptionTestProduct.identifier, price: NSDecimalNumber(string: "1.00"), priceLocale: .current, subscriptionPeriod: mockSubscriptionPeriod, introductoryOffer: introductoryOffer)
            
            let purchase = Purchase(from: .availableProduct(mockProduct), for: subscriptionTestProduct)
            
            XCTAssertNotNil(purchase.subscriptionTerms)
            
            if let terms = purchase.subscriptionTerms {
                XCTAssertNil(terms.introductoryOffer)
            }
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
    
    func testLocalizedTitleAndDescriptionMatchUnderlyingSKProduct() {
        let product = Product(identifier: "testProduct", kind: .nonConsumable)
        let skProduct = MockSKProduct(productIdentifier: product.identifier, price: NSDecimalNumber(string: "1.99"), priceLocale: Locale(identifier: "en_US_POSIX"), localizedTitle: "LocalizedTitle", localizedDescription: "LocalizedDescription")
        
        let purchase = Purchase(from: .availableProduct(skProduct), for: product)
        
        XCTAssertEqual(purchase.localizedTitle, "LocalizedTitle")
        XCTAssertEqual(purchase.localizedDescription, "LocalizedDescription")
    }
}
