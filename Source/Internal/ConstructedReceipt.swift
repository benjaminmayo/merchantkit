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
    
    var description: String {
        return self.defaultDescription(withProperties: ("productIdentifiers", self.productIdentifiers))
    }
    
    var debugDescription: String {
        var description = "ConstructedReceipt\n"
        
        for productIdentifier in self.entries.keys {
            description += "\n"
            description += "- \(productIdentifier) "
            
            let entries = self.entries[productIdentifier]
            
            description += "(\(entries.count) entries)\n"
            
            for entry in entries {
                description += "\t- \(entry)\n"
            }
        }
        
        return description
    }
    
    func entries(forProductIdentifier productIdentifier: String) -> [ReceiptEntry] {
        return self.entries[productIdentifier]
    }
}
