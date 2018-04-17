/// A Receipt instance represents a `StoreKit` receipt that has been parsed from raw data and then validated. Receipts can be produced using a custom flow or using a framework-provided validator.
public protocol Receipt : CustomStringConvertible, CustomDebugStringConvertible {
    /// Product identifiers represented in this receipt
    var productIdentifiers: Set<String> { get }
    
    /// All entries available for the given `productIdentifier`.
    func entries(forProductIdentifier productIdentifier: String) -> [ReceiptEntry]
}

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
