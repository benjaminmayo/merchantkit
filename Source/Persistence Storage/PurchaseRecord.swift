import Foundation

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
    
    private let productIdentifierKey: String = "productIdentifier"
    private let expiryDateKey: String = "expiryDate"
}

extension PurchaseRecord {
    internal init?(from dictionaryRepresentation: [String : Any]) {
        guard let productIdentifier = dictionaryRepresentation[self.productIdentifierKey] as? String else { return nil }
        let expiryDate = dictionaryRepresentation[self.expiryDateKey] as? Date
        
        self.productIdentifier = productIdentifier
        self.expiryDate = expiryDate as Date?
    }
    
    internal var dictionaryRepresentation: [String : AnyHashable] {
        var dict: [String : AnyHashable] = [
            self.productIdentifierKey: self.productIdentifier,
        ]
        
        if let expiryDate = self.expiryDate {
            dict[self.expiryDateKey] = expiryDate as Date
        }
        
        return dict
    }
}
