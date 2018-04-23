/// The `PurchasedState` represents the known state of a product as deemed by a `Merchant`.
public enum PurchasedState : Equatable {
    /// In the `unknown` state, the `Merchant` cannot definitively know whether a product should be considered purchased. The application should decide whether to be lenient or strict in allowing access to the product. This state is rare.
    case unknown
    /// The user has not purchased the product. The application should not allow the user to access the product, and may want to advertise the purchase of the product to the user.
    case notPurchased
    /// The user has purchased the product. The application should provide access to the product. `PurchasedProductInfo` contains additional metadata and information.
    case isPurchased(PurchasedProductInfo)
    
    /// Convenience accessor to determine if the product has been purchased. If `true`, the application should unambiguously provide access to the product.
    public var isPurchased: Bool {
        switch self {
            case .isPurchased(_):
                return true
            default:
                return false
        }
    }
}
