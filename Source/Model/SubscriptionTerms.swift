public struct SubscriptionTerms : Equatable {    
    public let duration: SubscriptionDuration
    
    public let introductoryOffer: IntroductoryOffer?
    
    public enum IntroductoryOffer : Equatable {
        case freeTrial(period: SubscriptionPeriod)
        case upfrontDiscount(price: Price, period: SubscriptionPeriod)
        case recurringDiscount(price: Price, period: SubscriptionPeriod)
    }
}
