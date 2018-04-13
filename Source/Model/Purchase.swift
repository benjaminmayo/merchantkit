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
    
    /// Describes the terms of the subscription purchase, such as renewal period and any introductory offers. Returns nil for non-subscription purchases.
    @available(iOS 11.2, *)
    public var subscriptionTerms: SubscriptionTerms? {
        func subscriptionPeriod(from skSubscriptionPeriod: SKProductSubscriptionPeriod) -> SubscriptionPeriod {
            let unitCount = skSubscriptionPeriod.numberOfUnits
            let unit: SubscriptionPeriod.Unit
            
            switch skSubscriptionPeriod.unit {
                case .day:
                    unit = .day
                case .week:
                    unit = .week
                case .month:
                    unit = .month
                case .year:
                    unit = .year
            }
            
            return SubscriptionPeriod(unit: unit, unitCount: unitCount)
        }
        
        guard let skSubscriptionPeriod = self.skProduct.subscriptionPeriod else {
            return nil
        }
        
        let period: SubscriptionPeriod = subscriptionPeriod(from: skSubscriptionPeriod)
        let introductoryOffer: SubscriptionTerms.IntroductoryOffer? = {
            if let skDiscount = self.skProduct.introductoryPrice {
                let locale = priceLocaleFromProductDiscount(skDiscount) ?? Locale.current
                
                let price = Price(from: skDiscount.price, in: locale)
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
        
        return SubscriptionTerms(renewalPeriod: period, introductoryOffer: introductoryOffer)
    }
    
    public static func ==(lhs: Purchase, rhs: Purchase) -> Bool {
        return lhs.productIdentifier == rhs.productIdentifier && lhs.price == rhs.price 
    }
}
