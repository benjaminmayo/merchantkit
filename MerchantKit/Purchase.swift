import StoreKit

/// A `Purchase` represents a possible transaction between the application and the user. 
// A typical flow comprises fetching possible purchases using the `AvailablePurchasesTask`, then displaying these purchases to the user in UI. Begin buying a `Purchase` using the `CommitPurchaseTask`.
public struct Purchase : Hashable, CustomStringConvertible {
    public let productIdentifier: String
    public let price: Price
    
    internal let skProduct: SKProduct
    
    internal init(productIdentifier: String, price: Price, skProduct: SKProduct) {
        self.productIdentifier = productIdentifier
        self.price = price
        self.skProduct = skProduct
    }
    
    public var description: String {
        return self.defaultDescription(withProperties: ("", "'\(self.productIdentifier)'"), ("price", self.price))
    }
    
    public var hashValue: Int {
        return self.productIdentifier.hashValue
    }
    
    public static func ==(lhs: Purchase, rhs: Purchase) -> Bool {
        return lhs.productIdentifier == rhs.productIdentifier && lhs.price == rhs.price 
    }
}
