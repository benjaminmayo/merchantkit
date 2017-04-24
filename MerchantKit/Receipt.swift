public struct Receipt {
    public let entries: [Entry]
    
    public init(entries: [Entry]) {
        self.entries = entries
    }
    
    public struct Entry {
        public let productIdentifier: String
        public let expiryDate: Date?
    }
}
