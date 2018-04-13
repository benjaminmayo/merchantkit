public struct SubscriptionTerms : Equatable {
    public let renewalPeriod: SubscriptionPeriod
    public let introductoryOffer: IntroductoryOffer?
    
    public enum IntroductoryOffer : Equatable {
        case freeTrial(period: SubscriptionPeriod)
        case upfrontDiscount(price: Price, period: SubscriptionPeriod)
        case recurringDiscount(price: Price, period: SubscriptionPeriod)
    }
}
