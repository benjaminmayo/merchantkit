import Foundation

internal struct ReceiptMetadataValues {
    public var originalApplicationVersion: String = ""
    public var bundleIdentifier: String?
    public var creationDate: Date?
    public var transactionIdentifier: String?
    public var originalTransactionIdentifier: String?
    public var purchaseDate: Date?
    public var originalPurchaseDate: Date?
    public var subscriptionExpirationDate: Date?
}
