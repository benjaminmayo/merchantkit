public struct ReceiptMetadata : Equatable {
    public let originalApplicationVersion: String
    
    internal init(originalApplicationVersion: String) {
        self.originalApplicationVersion = originalApplicationVersion
    }
}
