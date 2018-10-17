import Foundation 
import StoreKit

/// A `Purchase` represents a possible transaction between the application and the user. 
/// A typical flow comprises fetching possible purchases using the `AvailablePurchasesTask`, then displaying these purchases to the user in UI. Begin buying a `Purchase` using the `CommitPurchaseTask`.
public struct Purchase : Hashable, CustomStringConvertible {
    public let productIdentifier: String
    public let price: Price
    
    internal let skProduct: SKProduct
    internal let characteristics: Characteristics
    
    internal init(from skProduct: SKProduct, characteristics: Characteristics) {
        self.productIdentifier = skProduct.productIdentifier
        self.price = Price(from: skProduct.price, in: skProduct.priceLocale)
        
        self.skProduct = skProduct
        self.characteristics = characteristics
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
                let introductoryPeriod = subscriptionPeriod(from: skDiscount.subscriptionPeriod)
                
                switch skDiscount.paymentMode {
                    case .payAsYouGo:
                        return .recurringDiscount(discountedPrice: price, recurringPeriod: introductoryPeriod, discountedPeriodCount: skDiscount.numberOfPeriods)
                    case .payUpFront:
                        let totalPeriod = SubscriptionPeriod(unit: introductoryPeriod.unit, unitCount: introductoryPeriod.unitCount * skDiscount.numberOfPeriods)
                        
                        return .upfrontDiscount(discountedPrice: price, period: totalPeriod)
                    case .freeTrial:
                        return .freeTrial(period: introductoryPeriod)
                }
            } else {
                return nil
            }
        }()
        
        let duration = SubscriptionDuration(period: period, isRecurring: self.characteristics.contains(.isAutorenewingSubscription))
        
        return SubscriptionTerms(duration: duration, introductoryOffer: introductoryOffer)
    }
    
    public static func ==(lhs: Purchase, rhs: Purchase) -> Bool {
        return lhs.productIdentifier == rhs.productIdentifier && lhs.price == rhs.price && lhs.characteristics == rhs.characteristics
    }
}

extension Purchase {
    /// This type is not intended to ever be publicly exposed. It carries internal metadata.
    internal struct Characteristics : OptionSet {
        let rawValue: UInt
        
        init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        
        public static let isAutorenewingSubscription: Characteristics = Characteristics(rawValue: 1 << 1)
    }
}
