import StoreKit

@available (iOS 11.2, *)
internal class MockSKProductWithSubscription : SKProduct {
    private let _productIdentifier: String
    private let _price: NSDecimalNumber
    private let _priceLocale: Locale
    private let _subscriptionPeriod: SKProductSubscriptionPeriod?
    private let _introductoryOffer: SKProductDiscount?
    private let _discounts: [SKProductDiscount]
    
    internal init(productIdentifier: String, price: NSDecimalNumber, priceLocale: Locale, subscriptionPeriod: SKProductSubscriptionPeriod?, introductoryOffer: SKProductDiscount?, discounts: [SKProductDiscount] = []) {
        self._productIdentifier = productIdentifier
        self._price = price
        self._priceLocale = priceLocale
        self._subscriptionPeriod = subscriptionPeriod
        self._introductoryOffer = introductoryOffer
        
        self._discounts = discounts
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
    
    override var discounts: [SKProductDiscount] {
        return self._discounts
    }
}
