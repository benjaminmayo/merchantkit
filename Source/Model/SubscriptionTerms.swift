public struct SubscriptionTerms: Equatable {
    public let duration: SubscriptionDuration
    
    public let introductoryOffer: Discount?
    public let discounts: [Discount]?
    
    public enum Discount: Equatable {
        case freeTrial(period: SubscriptionPeriod)
        case upfrontDiscount(discountedPrice: Price, period: SubscriptionPeriod)
        case recurringDiscount(discountedPrice: Price, recurringPeriod: SubscriptionPeriod, discountedPeriodCount: Int)
    }
}
