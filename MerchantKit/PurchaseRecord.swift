import Foundation

internal struct PurchaseRecord : Equatable {
    internal let productIdentifier: String
    internal let expiryDate: Date?
    internal let isPurchased: Bool
    
    internal static func ==(lhs: PurchaseRecord, rhs: PurchaseRecord) -> Bool {
        return lhs.productIdentifier == rhs.productIdentifier && lhs.expiryDate == rhs.expiryDate && lhs.isPurchased == rhs.isPurchased
    }
}
