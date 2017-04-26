public protocol Receipt {
    /// Product identifiers represented in this receipt
    var productIdentifiers: Set<String> { get }
    
    /// All entries available for the given `productIdentifier`.
    func entries(forProductIdentifier productIdentifier: String) -> [ReceiptEntry]
}

public struct ReceiptEntry { // Ideally, this would be Receipt.Entry
    public let productIdentifier: String
    public let expiryDate: Date?
    
    public init(productIdentifier: String, expiryDate: Date?) {
        self.productIdentifier = productIdentifier
        self.expiryDate = expiryDate
    }
}
