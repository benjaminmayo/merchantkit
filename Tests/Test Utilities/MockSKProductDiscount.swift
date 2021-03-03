import XCTest
import StoreKit

@available(iOS 11.2, *)
internal class MockSKProductDiscount : SKProductDiscount {
    private let _price: NSDecimalNumber
    private let _priceLocale: Locale
    private let _subscriptionPeriod: SKProductSubscriptionPeriod
    private let _numberOfPeriods: Int
    private let _paymentMode: SKProductDiscount.PaymentMode
    
    internal init(price: NSDecimalNumber, priceLocale: Locale, subscriptionPeriod: SKProductSubscriptionPeriod, numberOfPeriods: Int, paymentMode: SKProductDiscount.PaymentMode) {
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

@available(iOS 12.2, *)
internal class MockSKProductDiscountWithIdentifier : MockSKProductDiscount {
    private let _identifier: String
    
    internal init(identifier: String, price: NSDecimalNumber, priceLocale: Locale, subscriptionPeriod: SKProductSubscriptionPeriod, numberOfPeriods: Int, paymentMode: SKProductDiscount.PaymentMode) {
        self._identifier = identifier
    
        super.init(price: price, priceLocale: priceLocale, subscriptionPeriod: subscriptionPeriod, numberOfPeriods: numberOfPeriods, paymentMode: paymentMode)
    }
    
    override var identifier: String? {
        return self._identifier
    }
}
