import StoreKit

/// A `Purchase` represents a possible transaction between the application and the user. 
// A typical flow comprises fetching possible purchases using the `AvailablePurchasesTask`, then displaying these purchases to the user in UI. Begin buying a `Purchase` using the `CommitPurchaseTask`.
public struct Purchase : Hashable, CustomStringConvertible {
    public let productIdentifier: String
    public let price: Price
    
    internal let skProduct: SKProduct
    
    internal init(from skProduct: SKProduct) {
        self.productIdentifier = skProduct.productIdentifier
        self.price = Price(from: skProduct.price, in: skProduct.priceLocale)
        self.skProduct = skProduct
    }
    
    public var description: String {
        return self.defaultDescription(withProperties: ("", "'\(self.productIdentifier)'"), ("price", self.price))
    }
    
    public var hashValue: Int {
        return self.productIdentifier.hashValue
    }
    
    @available(iOS 11.2, *)
    public var subscriptionInfo: SubscriptionInfo? {
        func subscriptionPeriod(from skSubscriptionPeriod: SKProductSubscriptionPeriod) -> SubscriptionInfo.Period {
            let unitCount = skSubscriptionPeriod.numberOfUnits
            
            switch skSubscriptionPeriod.unit {
                case .day:
                    return .days(unitCount: unitCount)
                case .week:
                    return .weeks(unitCount: unitCount)
                case .month:
                    return .months(unitCount: unitCount)
                case .year:
                    return .years(unitCount: unitCount)
            }
        }
        
        guard let skSubscriptionPeriod = self.skProduct.subscriptionPeriod else {
            return nil
        }
        
        let period: SubscriptionInfo.Period = subscriptionPeriod(from: skSubscriptionPeriod)
        let introductoryOffer: SubscriptionInfo.IntroductoryOffer? = {
            if let skDiscount = self.skProduct.introductoryPrice {
                let price = Price(from: skDiscount.price, in: skDiscount.priceLocale)
                let period = subscriptionPeriod(from: skDiscount.subscriptionPeriod)
                
                switch skDiscount.paymentMode {
                    case .payAsYouGo:
                        return .recurringDiscount(price: price, period: period)
                    case .payUpFront:
                        return .upfrontDiscount(price: price, period: period)
                    case .freeTrial:
                        return .freeTrial(period: period)
                }
            } else {
                return nil
            }
        }()
        
        return SubscriptionInfo(renewalPeriod: period, introductoryOffer: introductoryOffer)
    }
    
    public static func ==(lhs: Purchase, rhs: Purchase) -> Bool {
        return lhs.productIdentifier == rhs.productIdentifier && lhs.price == rhs.price 
    }
}
