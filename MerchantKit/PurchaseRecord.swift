/// A storage item encapsulating information about a purchase.
public struct PurchaseRecord : Equatable, CustomStringConvertible {
    /// The unique string identifying a particular product.
    public let productIdentifier: String
    /// The expiry date for the purchase, if appropriate.
    public let expiryDate: Date?
    
    public init(productIdentifier: String, expiryDate: Date?) {
        self.productIdentifier = productIdentifier
        self.expiryDate = expiryDate
    }
    
    public var description: String {
        return self.defaultDescription(withProperties: ("productIdentifier", self.productIdentifier), ("expiryDate", self.expiryDate ?? "nil"))
    }
    
    public static func ==(lhs: PurchaseRecord, rhs: PurchaseRecord) -> Bool {
        return lhs.productIdentifier == rhs.productIdentifier && lhs.expiryDate == rhs.expiryDate
    }
    
    fileprivate let productIdentifierKey: String = "productIdentifier"
    fileprivate let expiryDateKey: String = "expiryDate"
}

extension PurchaseRecord {
    var dictionaryRepresentation: [String : Any] {
        var dict: [String : Any] = [
            self.productIdentifierKey: self.productIdentifier,
        ]
        
        if let expiryDate = self.expiryDate {
            dict[self.expiryDateKey] = expiryDate as NSDate
        }
        
        return dict
    }
    
    init?(from dictionaryRepresentation: [String : Any]) {
        guard let productIdentifier = dictionaryRepresentation[self.productIdentifierKey] as? String else { return nil }
        let expiryDate = dictionaryRepresentation[self.expiryDateKey] as? NSDate
        
        self.productIdentifier = productIdentifier
        self.expiryDate = expiryDate as Date?
    }
}
