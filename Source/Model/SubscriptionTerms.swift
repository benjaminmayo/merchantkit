/// This type contains information relating to a subscription purchase. You may be interested in display the subscription `duration`in the user interface. Refer to `SubscriptionPriceFormatter` for more information.
/// The `introductoryOffer` is available the first time the `Product` is purchased. A `RetentionOffer` can be used after the user has already purchased the product at least once, to entice them back in.
public struct SubscriptionTerms : Equatable {
    public let duration: SubscriptionDuration
    
    public let introductoryOffer: IntroductoryOffer?
    public let availableRetentionOffers: [RetentionOffer]
    
    public enum IntroductoryOffer : Equatable {
        case freeTrial(period: SubscriptionPeriod)
        case upfrontDiscount(discountedPrice: Price, period: SubscriptionPeriod)
        case recurringDiscount(discountedPrice: Price, recurringPeriod: SubscriptionPeriod, discountedPeriodCount: Int)
    }
    
    /// The `RetentionOffer` encapsulates information about the discount promotion available, and an identifier. Use this identifier to generate the necessary parameters to instantiate an `PurchaseDiscount` instance.
    public struct RetentionOffer : Equatable {
        public let identifier: String
        public let discount: Discount
        
        public init(identifier: String, discount: Discount) {
            self.identifier = identifier
            self.discount = discount
        }
        
        public enum Discount : Equatable {
            case freeTerm(period: SubscriptionPeriod)
            case upfront(discountedPrice: Price, period: SubscriptionPeriod)
            case recurring(discountedPrice: Price, recurringPeriod: SubscriptionPeriod, discountedPeriodCount: Int)
        }
    }
}
