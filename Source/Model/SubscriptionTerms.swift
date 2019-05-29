public struct SubscriptionTerms : Equatable {
    public let duration: SubscriptionDuration
    
    public let introductoryOffer: IntroductoryOffer?
    public let availableRetentionOffers: [RetentionOffer]
    
    public enum IntroductoryOffer : Equatable {
        case freeTrial(period: SubscriptionPeriod)
        case upfrontDiscount(discountedPrice: Price, period: SubscriptionPeriod)
        case recurringDiscount(discountedPrice: Price, recurringPeriod: SubscriptionPeriod, discountedPeriodCount: Int)
    }
    
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
