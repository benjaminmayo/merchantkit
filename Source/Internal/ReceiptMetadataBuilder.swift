import Foundation

internal struct ReceiptMetadataBuilder {
    var originalApplicationVersion: String = ""
    var bundleIdentifier: String = ""
    var creationDate: Date?
    
    init() {
        
    }
    
    func build() -> ReceiptMetadata {
        return ReceiptMetadata(originalApplicationVersion: self.originalApplicationVersion, bundleIdentifier: self.bundleIdentifier, creationDate: self.creationDate)
    }
}
