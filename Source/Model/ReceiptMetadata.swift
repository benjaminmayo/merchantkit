import Foundation

public struct ReceiptMetadata : Equatable {
    public let originalApplicationVersion: String
    public let bundleIdentifier: String
    public let creationDate: Date?

    public init(originalApplicationVersion: String = "", bundleIdentifier: String = "", creationDate: Date? = nil) {
        self.originalApplicationVersion = originalApplicationVersion
        self.bundleIdentifier = bundleIdentifier
        self.creationDate = creationDate
    }
}
