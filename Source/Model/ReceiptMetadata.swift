import Foundation

public struct ReceiptMetadata : Equatable {
    public let originalApplicationVersion: String
    public let bundleIdentifier: String?
    public let creationDate: Date?
    public let transactionIdentifier: String?
    public let originalTransactionIdentifier: String?
    public let purchaseDate: Date?
    public let originalPurchaseDate: Date?
    public let subscriptionExpirationDate: Date?

    internal init(originalApplicationVersion: String) {
        self.originalApplicationVersion = originalApplicationVersion
        bundleIdentifier = nil
        creationDate = nil
        transactionIdentifier = nil
        originalTransactionIdentifier = nil
        purchaseDate = nil
        originalPurchaseDate = nil
        subscriptionExpirationDate = nil
    }

    internal init(originalApplicationVersion: String, bundleIdentifier: String?, creationDate: Date?, transactionIdentifier: String?, originalTransactionIdentifier: String?, purchaseDate: Date?, originalPurchaseDate: Date?, subscriptionExpirationDate: Date?) {
        self.originalApplicationVersion = originalApplicationVersion
        self.bundleIdentifier = bundleIdentifier
        self.creationDate = creationDate
        self.transactionIdentifier = transactionIdentifier
        self.originalTransactionIdentifier = originalTransactionIdentifier
        self.purchaseDate = purchaseDate
        self.originalPurchaseDate = originalPurchaseDate
        self.subscriptionExpirationDate = subscriptionExpirationDate
    }

    internal init(withMetadataValues values: ReceiptMetadataValues) {
        originalApplicationVersion = values.originalApplicationVersion
        bundleIdentifier = values.bundleIdentifier
        creationDate = values.creationDate
        transactionIdentifier = values.transactionIdentifier
        originalTransactionIdentifier = values.originalTransactionIdentifier
        purchaseDate = values.purchaseDate
        originalPurchaseDate = values.originalPurchaseDate
        subscriptionExpirationDate = values.subscriptionExpirationDate
    }
}
