/// Describes a duration of a subscription in an abstract form. This type currently cannot be instantiated outside of the framework, this may change in a future release.
public struct SubscriptionPeriod : Hashable {
    public let unit: Unit
    public let unitCount: Int
    
    /// Create a `SubscriptionPeriod` with the given `unit` and `unitCount`. A `Unit.day` with a count of 5 represents five days, for example.
    /// Typically, you do not need to construct `SubscriptionPeriod` instances manually.
    public init(unit: Unit, unitCount: Int) {
        self.unit = unit
        self.unitCount = unitCount
    }
    
    public enum Unit : Equatable {
        case day
        case week
        case month
        case year
    }
}

// internal convenience constructors that may warrant becoming public in future
extension SubscriptionPeriod {
    internal static func days(_ unitCount: Int) -> SubscriptionPeriod {
        return SubscriptionPeriod(unit: .day, unitCount: unitCount)
    }
    
    internal static func weeks(_ unitCount: Int) -> SubscriptionPeriod {
        return SubscriptionPeriod(unit: .week, unitCount: unitCount)
    }
    
    internal static func months(_ unitCount: Int) -> SubscriptionPeriod {
        return SubscriptionPeriod(unit: .month, unitCount: unitCount)
    }
    
    internal static func years(_ unitCount: Int) -> SubscriptionPeriod {
        return SubscriptionPeriod(unit: .year, unitCount: unitCount)
    }
    
}
