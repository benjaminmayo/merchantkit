import Foundation

public struct PurchaseRecord : Equatable, CustomStringConvertible {
    public let productIdentifier: String
    public let expiryDate: Date?
    public let isPurchased: Bool
    
    public init(productIdentifier: String, expiryDate: Date?, isPurchased: Bool) {
        self.productIdentifier = productIdentifier
        self.expiryDate = expiryDate
        self.isPurchased = isPurchased
    }
    
    public var description: String {
        return self.defaultDescription(withProperties: ("productIdentifier", self.productIdentifier), ("isPurchased", self.isPurchased), ("expiryDate", self.expiryDate ?? "nil"))
    }
    
    public static func ==(lhs: PurchaseRecord, rhs: PurchaseRecord) -> Bool {
        return lhs.productIdentifier == rhs.productIdentifier && lhs.expiryDate == rhs.expiryDate && lhs.isPurchased == rhs.isPurchased
    }
    
    fileprivate let productIdentifierKey: String = "productIdentifier"
    fileprivate let expiryDateKey: String = "expiryDate"
    fileprivate let isPurchasedKey: String = "isPurchased"
}

extension PurchaseRecord {
    var dictionaryRepresentation: [String : Any] {
        var dict: [String : Any] = [
            self.productIdentifierKey: self.productIdentifier,
            self.isPurchasedKey: NSNumber(value: self.isPurchased)
        ]
        
        if let expiryDate = self.expiryDate {
            dict[self.expiryDateKey] = expiryDate as NSDate
        }
        
        return dict
    }
    
    init?(from dictionaryRepresentation: [String : Any]) {
        guard let productIdentifier = dictionaryRepresentation[self.productIdentifierKey] as? String else { return nil }
        let expiryDate = dictionaryRepresentation[self.expiryDateKey] as? NSDate
        let isPurchased = (dictionaryRepresentation[self.isPurchasedKey] as? NSNumber)?.boolValue ?? false
        
        self.productIdentifier = productIdentifier
        self.expiryDate = expiryDate as Date?
        self.isPurchased = isPurchased
    }
}
