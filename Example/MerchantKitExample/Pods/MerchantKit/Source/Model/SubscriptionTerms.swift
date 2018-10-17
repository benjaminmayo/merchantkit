public struct SubscriptionTerms : Equatable {    
    public let duration: SubscriptionDuration
    
    public let introductoryOffer: IntroductoryOffer?
    
    public enum IntroductoryOffer : Equatable {
        case freeTrial(period: SubscriptionPeriod)
        case upfrontDiscount(discountedPrice: Price, period: SubscriptionPeriod)
        case recurringDiscount(discountedPrice: Price, recurringPeriod: SubscriptionPeriod, discountedPeriodCount: Int)
    }
}
