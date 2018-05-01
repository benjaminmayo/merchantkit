import XCTest
import Foundation
import StoreKit
@testable import MerchantKit

class PurchaseTests : XCTestCase {
    func testHash() {
        let mockProduct = MockSKProduct(productIdentifier: "testProduct", price: NSDecimalNumber(string: "1.00"), priceLocale: .current)
        
        let purchase = Purchase(from: mockProduct, characteristics: [])
        XCTAssertEqual(purchase.hashValue, mockProduct.productIdentifier.hashValue)
    }
    
    @available(iOS 11.2, *)
    func testMatchingSubscriptionPeriod() {
        let expectations: [(SKProduct.PeriodUnit, SubscriptionPeriod.Unit)] = [
            (.day, .day),
            (.week, .week),
            (.month, .month),
            (.year, .year)
        ]
        
        for (numberOfUnits, expectation) in expectations.enumerated() {
            let mockSubscriptionPeriod = MockSKProductSubscriptionPeriod(unit: expectation.0, numberOfUnits: numberOfUnits)
            let mockProduct = MockSKProductWithSubscription(productIdentifier: "testProduct", price: NSDecimalNumber(string: "1.00"), priceLocale: .current, subscriptionPeriod: mockSubscriptionPeriod, introductoryOffer: nil)
            
            let purchase = Purchase(from: mockProduct, characteristics: [])
            
            let terms = purchase.subscriptionTerms
            XCTAssertNotNil(terms)
            
            let period = SubscriptionPeriod(unit: expectation.1, unitCount: numberOfUnits)
            let duration = SubscriptionDuration(period: period, isRecurring: false)
            XCTAssertEqual(terms!.duration, duration)
        }
    }
    
    @available(iOS 11.2, *)
    func testMatchingSubscriptionIntroductoryOffer() {
        let mockSubscriptionPeriod = MockSKProductSubscriptionPeriod(unit: .month, numberOfUnits: 1)
        
        let expectations: [(SKProductDiscount, SubscriptionTerms.IntroductoryOffer)] = [
            (MockSKProductDiscount(price: NSDecimalNumber(string: "1.00"), priceLocale: .current, subscriptionPeriod: mockSubscriptionPeriod, numberOfPeriods: 6, paymentMode: .payAsYouGo), SubscriptionTerms.IntroductoryOffer.recurringDiscount(discountedPrice: Price(from: NSDecimalNumber(string: "1.00"), in: .current), recurringPeriod: .months(1), discountedPeriodCount: 6)),
            (MockSKProductDiscount(price: NSDecimalNumber(string: "1.00"), priceLocale: .current, subscriptionPeriod: mockSubscriptionPeriod, numberOfPeriods: 6, paymentMode: .payUpFront), SubscriptionTerms.IntroductoryOffer.upfrontDiscount(discountedPrice: Price(from: NSDecimalNumber(string: "1.00"), in: .current), period: .months(6))),
            (MockSKProductDiscount(price: NSDecimalNumber(string: "0.00"), priceLocale: .current, subscriptionPeriod: mockSubscriptionPeriod, numberOfPeriods: 1, paymentMode: .freeTrial), SubscriptionTerms.IntroductoryOffer.freeTrial(period: .months(1)))
        ]

        for expectation in expectations {
            let mockProduct = MockSKProductWithSubscription(productIdentifier: "testProduct", price: NSDecimalNumber(string: "1.00"), priceLocale: .current, subscriptionPeriod: mockSubscriptionPeriod, introductoryOffer: expectation.0)
            
            let purchase = Purchase(from: mockProduct, characteristics: [])
            
            let terms = purchase.subscriptionTerms
            XCTAssertNotNil(terms)
            
            let introductoryOffer = terms!.introductoryOffer
            XCTAssertNotNil(introductoryOffer)
            
            XCTAssertEqual(introductoryOffer!, expectation.1)
        }
    }
    
    @available(iOS 11.2, *)
    func testNoSubscriptionPeriod() {
        let mockProduct = MockSKProductWithSubscription(productIdentifier: "testProduct", price: NSDecimalNumber(string: "1.00"), priceLocale: .current, subscriptionPeriod: nil, introductoryOffer: nil)
        let purchase = Purchase(from: mockProduct, characteristics: [])
        
        XCTAssertNil(purchase.subscriptionTerms)
    }
    
    func testCustomizedHashableConformance() {
        let locale = Locale(identifier: "en-US")
        let number = NSDecimalNumber(string: "9.99")
        
        let price = Price(from: number, in: locale)
        let equivalentPrice = Price(from: number, in: locale)
        
        XCTAssertEqual(price, equivalentPrice)
        XCTAssertEqual(price.hashValue, equivalentPrice.hashValue)
    }
}

private class MockSKProduct : SKProduct {
    private let _productIdentifier: String
    private let _price: NSDecimalNumber
    private let _priceLocale: Locale
    
    init(productIdentifier: String, price: NSDecimalNumber, priceLocale: Locale) {
        self._productIdentifier = productIdentifier
        self._price = price
        self._priceLocale = priceLocale
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
}

@available(iOS 11.2, *)
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
