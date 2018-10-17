/// Describes metadata for the given purchased non-consumable or subscription product. Some fields may not be available at all times.
public struct PurchasedProductInfo : Equatable {
    /// Subscription products may have expiry dates available to present. For non-consumable products, this value will always be `nil`.
    /// - Note: Do not use this value to decide whether to allow access to the product.
    public let expiryDate: Date?
}
