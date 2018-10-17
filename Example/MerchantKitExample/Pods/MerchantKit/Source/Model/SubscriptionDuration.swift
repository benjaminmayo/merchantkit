/// Defines the length of a subscription, as well as indicating whether it will repeat (recur) until cancelled.
public struct SubscriptionDuration : Hashable {
    public let period: SubscriptionPeriod
    public let isRecurring: Bool
}
