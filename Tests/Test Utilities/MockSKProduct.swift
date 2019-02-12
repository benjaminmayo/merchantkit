import StoreKit

class MockSKProduct : SKProduct {
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
