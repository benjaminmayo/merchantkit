public struct SubscriptionInfo {
    public let renewalPeriod: Period
    public let introductoryOffer: IntroductoryOffer?
    
    public enum Period {
        case days(unitCount: Int)
        case weeks(unitCount: Int)
        case months(unitCount: Int)
        case years(unitCount: Int)
        
        public var unitCount: Int {
            switch self {
                case .days(let unitCount): return unitCount
                case .weeks(let unitCount): return unitCount
                case .months(let unitCount): return unitCount
                case .years(let unitCount): return unitCount
            }
        }
    }
    
    public enum IntroductoryOffer {
        case freeTrial(period: Period)
        case upfrontDiscount(price: Price, period: Period)
        case recurringDiscount(price: Price, period: Period)
    }
}
