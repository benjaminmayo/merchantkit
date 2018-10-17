/// `ConstructedReceipt` accepts an eager array of `ReceiptEntry` items and interfaces as a `Receipt`.
/// This is used by the `ServerReceiptResponseParser` to make its validated receipt.
internal struct ConstructedReceipt : Receipt, CustomStringConvertible, CustomDebugStringConvertible {
    var productIdentifiers: Set<String> {
        return self.entries.keys
    }
    
    private let entries: Buckets<String, ReceiptEntry>
    
    init(from allEntries: [ReceiptEntry]) {
        var entriesForProductIdentifier = Buckets<String, ReceiptEntry>()
        
        for entry in allEntries {
            entriesForProductIdentifier[entry.productIdentifier].append(entry)
        }
        
        self.entries = entriesForProductIdentifier
    }
    
    func entries(forProductIdentifier productIdentifier: String) -> [ReceiptEntry] {
        return self.entries[productIdentifier]
    }
}
