/// A Receipt instance represents a `StoreKit` receipt that has been parsed from raw data and then validated. Receipts can be produced using a custom flow or using a framework-provided validator.
public protocol Receipt : CustomStringConvertible, CustomDebugStringConvertible {
    // Salient metadata that applies to the receipt as a whole.
    var metadata: ReceiptMetadata { get }
    
    /// Product identifiers represented in this receipt.
    var productIdentifiers: Set<String> { get }
    
    /// All entries available for the given `productIdentifier`.
    func entries(forProductIdentifier productIdentifier: String) -> [ReceiptEntry]
}

// MARK: Default `description` and `debugDescription` implementations for `Receipt` instances
extension Receipt {
    var description: String {
        return self.defaultDescription(withProperties: ("productIdentifiers", self.productIdentifiers))
    }
    
    public var debugDescription: String {
        var description = "\(type(of: self))\n"
        
        let sortedProductIdentifiers = self.productIdentifiers.sorted()
        
        let lastProductIdentifierIndex = sortedProductIdentifiers.count - 1
        
        for (index, productIdentifier) in sortedProductIdentifiers.enumerated() {
            description += "\n"
            description += "\t- \(productIdentifier) "
            
            let entries = self.entries(forProductIdentifier: productIdentifier)
            let lastEntryIndex = entries.count - 1
            
            description += "(\(entries.count) entries)\n"
            
            for (index, entry) in entries.enumerated() {
                description += "\t\t- \(entry)"
                
                if index < lastEntryIndex {
                    description += "\n"
                }
            }
            
            if index < lastProductIdentifierIndex {
                description += "\n"
            }
        }
        
        return description
    }
}
