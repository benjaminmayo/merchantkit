import Foundation

public struct ReceiptMetadata : Equatable {
    public let originalApplicationVersion: String
    public let bundleIdentifier: String
    public let creationDate: Date?

    internal init(from values: ReceiptMetadataValues) {
        self.originalApplicationVersion = values.originalApplicationVersion
        self.bundleIdentifier = values.bundleIdentifier
        self.creationDate = values.creationDate
    }
}
