import Foundation

internal struct ReceiptMetadataValues {
    var originalApplicationVersion: String
    var bundleIdentifier: String
    var creationDate: Date?
    
    internal init(originalApplicationVersion: String = "", bundleIdentifier: String = "", creationDate: Date? = nil) {
        self.originalApplicationVersion = originalApplicationVersion
        self.bundleIdentifier = bundleIdentifier
        self.creationDate = creationDate
    }
}
