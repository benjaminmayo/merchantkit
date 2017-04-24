public struct Receipt {
    public let productIdentifiers: Set<String>
    private let entriesForProductIdentifiers: [String : [Entry]]
    
    public init(entries: [Entry]) {
        var data = [String : [Entry]]()
        
        for entry in entries {
            var entriesForProductIdentifier = data[entry.productIdentifier] ?? []
            entriesForProductIdentifier.append(entry)
            
            data[entry.productIdentifier] = entriesForProductIdentifier
        }
        
        self.productIdentifiers = Set(data.keys)
        self.entriesForProductIdentifiers = data
    }
    
    public func entries(forProductIdentifier productIdentifier: String) -> [Entry] {
        return self.entriesForProductIdentifiers[productIdentifier] ?? []
    }
    
    public struct Entry {
        public let productIdentifier: String
        public let expiryDate: Date?
        
        init(productIdentifier: String, expiryDate: Date?) {
            self.productIdentifier = productIdentifier
            self.expiryDate = expiryDate
        }
    }
}
