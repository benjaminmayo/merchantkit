import Foundation

/// A `ReceiptEntry` represents the pertinent information for a product contained within a `StoreKit` receipt.
public struct ReceiptEntry : CustomStringConvertible { // Ideally, this would be Receipt.Entry
    /// The product identifier for a purchase.
    public let productIdentifier: String
    /// The expiry date for a subscription purchase, if available.
    public let expiryDate: Date?
    
    public init(productIdentifier: String, expiryDate: Date?) {
        self.productIdentifier = productIdentifier
        self.expiryDate = expiryDate
    }
    
    public var description: String {
        return self.defaultDescription(withProperties: ("productIdentifier", self.productIdentifier), ("expiryDate", self.expiryDate ?? "nil"))
    }
}
