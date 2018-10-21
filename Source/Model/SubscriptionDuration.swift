/// Defines the length of a subscription, as well as indicating whether it will repeat (recur) until cancelled.
public struct SubscriptionDuration : Hashable {
    public let period: SubscriptionPeriod
    public let isRecurring: Bool
    
    /// Create a new `SubscriptionDuration` with the specified period. A subscription is considered recurring when the subscription renews for multiple periods.
    public init(period: SubscriptionPeriod, isRecurring: Bool) {
        self.period = period
        self.isRecurring = isRecurring
    }
}
