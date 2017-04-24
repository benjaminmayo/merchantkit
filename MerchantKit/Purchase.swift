public struct Purchase : Hashable {
    public let productIdentifier: String
    public let price: Price
    
    internal init(productIdentifier: String, price: Price) {
        self.productIdentifier = productIdentifier
        self.price = price
    }
    
    public var hashValue: Int {
        return self.productIdentifier.hashValue
    }
    
    public static func ==(lhs: Purchase, rhs: Purchase) -> Bool {
        return lhs.productIdentifier == rhs.productIdentifier && lhs.price == rhs.price 
    }
}
