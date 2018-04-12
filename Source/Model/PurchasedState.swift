/// The purchased state of a product as deemed by the `Merchant`.
public enum PurchasedState : Equatable {
    case unknown // User may or may not have purchased the product. The application should decide to be lenient or strict regarding whether the user can access the product.
    case notPurchased // User has not purchased the product. The application should not allow the user to access the product.
    case isSold // User has bought the non-consumable product.
    case isSubscribed(expiryDate: Date?) // User has subscribed to the subscription product. An expiry date may not be available for display at all times.
    
    /// If you do not want to distinguish by product kind, check the `isPurchased` property to see if the associated product should be accessible to the user.
    public var isPurchased: Bool {
        switch self {
            case .unknown:
                return false
            case .notPurchased:
                return false
            case .isSold:
                return true
            case .isSubscribed(_):
                return true
        }
    }
}
