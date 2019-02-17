import StoreKit

class MockSKProduct : SKProduct {
    private let _productIdentifier: String
    private let _price: NSDecimalNumber
    private let _priceLocale: Locale
    private let _localizedTitle: String
    private let _localizedDescription: String
    
    init(productIdentifier: String, price: NSDecimalNumber, priceLocale: Locale, localizedTitle: String = "", localizedDescription: String = "") {
        self._productIdentifier = productIdentifier
        self._price = price
        self._priceLocale = priceLocale
        self._localizedTitle = localizedTitle
        self._localizedDescription = localizedDescription
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
    
    override var localizedTitle: String {
        return self._localizedTitle
    }
    
    override var localizedDescription: String {
        return self._localizedDescription
    }
}
