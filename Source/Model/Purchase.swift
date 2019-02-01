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
        self.price = Price(value: (skProduct.price as Decimal, skProduct.priceLocale))
        
        self.skProduct = skProduct
        self.characteristics = characteristics
    }
    
    public var description: String {
        return self.defaultDescription(withProperties: ("", "'\(self.productIdentifier)'"), ("price", self.price))
    }
    
    public var localizedTitle: String {
        return self.skProduct.localizedTitle
    }
    
    public var localizedDescription: String {
        return self.skProduct.localizedDescription
    }
    
    /// Describes the terms of the subscription purchase, such as renewal period and any introductory offers. Returns nil for non-subscription purchases.
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
                @unknown default:
                    fatalError("Unexpected value (\(skSubscriptionPeriod.unit.rawValue)) for `SKSubscriptionPeriod`.")
            }
            
            return SubscriptionPeriod(unit: unit, unitCount: unitCount)
        }
        
        guard self.characteristics.contains(.isSubscription), let skSubscriptionPeriod = self.skProduct.subscriptionPeriod else { // `SKProduct.subscriptionPeriod` can be non-nil for products that do not represent subscriptions, so we add in our own check here
            return nil
        }
        
        let period: SubscriptionPeriod = subscriptionPeriod(from: skSubscriptionPeriod)
        
        let introductoryOffer: SubscriptionTerms.IntroductoryOffer? = {
            if let skDiscount = self.skProduct.introductoryPrice {
                let locale = priceLocaleFromProductDiscount(skDiscount) ?? Locale.current
                
                let price = Price(value: (skDiscount.price as Decimal, locale))
                let introductoryPeriod = subscriptionPeriod(from: skDiscount.subscriptionPeriod)
                
                switch skDiscount.paymentMode {
                    case .payAsYouGo:
                        return .recurringDiscount(discountedPrice: price, recurringPeriod: introductoryPeriod, discountedPeriodCount: skDiscount.numberOfPeriods)
                    case .payUpFront:
                        let totalPeriod = SubscriptionPeriod(unit: introductoryPeriod.unit, unitCount: introductoryPeriod.unitCount * skDiscount.numberOfPeriods)
                        
                        return .upfrontDiscount(discountedPrice: price, period: totalPeriod)
                    case .freeTrial:
                        return .freeTrial(period: introductoryPeriod)
                    @unknown default:
                        fatalError("Unexpected value (\(skDiscount.paymentMode.rawValue)) for `SKProductDiscount.PaymentMode`.")
                }
            } else {
                return nil
            }
        }()
        
        let duration = SubscriptionDuration(period: period, isRecurring: self.characteristics.contains(.isAutorenewingSubscription))
        
        return SubscriptionTerms(duration: duration, introductoryOffer: introductoryOffer)
    }
}

extension Purchase {
    /// This type is not intended to ever be publicly exposed. It carries internal metadata.
    internal struct Characteristics : OptionSet, Hashable {
        let rawValue: UInt
        
        init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        
        public static let isSubscription: Characteristics = Characteristics(rawValue: 1 << 1)
        public static let isAutorenewingSubscription: Characteristics = Characteristics(rawValue: 1 << 2)
    }
}
