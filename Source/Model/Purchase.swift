import Foundation 
import StoreKit

/// A `Purchase` represents a possible transaction between the application and the user. 
/// A typical flow comprises fetching possible purchases using the `AvailablePurchasesTask`, then displaying these purchases to the user in UI. Begin buying a `Purchase` using the `CommitPurchaseTask`.
public struct Purchase : Hashable, CustomStringConvertible {
    public let productIdentifier: String
    public let price: Price

    internal let source: Source
    private let characteristics: Characteristics
    
    internal init(from source: Source, for product: Product) {
        var characteristics = Purchase.Characteristics()
        
        switch product.kind {
            case .subscription(automaticallyRenews: true):
                characteristics.insert(.isSubscription)
                characteristics.insert(.isAutorenewingSubscription)
            case .subscription(automaticallyRenews: false):
                characteristics.insert(.isSubscription)
            default:
                break
        }
        
        self.productIdentifier = product.identifier
        self.price = Price(value: (source.skProduct.price as Decimal, source.skProduct.priceLocale))
        
        self.source = source
        self.characteristics = characteristics
    }
    
    public var description: String {
        return self.defaultDescription(withProperties: ("", "'\(self.productIdentifier)'"), ("price", self.price))
    }
    
    public var localizedTitle: String {
        return self.source.skProduct.localizedTitle
    }
    
    public var localizedDescription: String {
        return self.source.skProduct.localizedDescription
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
        
        guard self.characteristics.contains(.isSubscription), let skSubscriptionPeriod = self.source.skProduct.subscriptionPeriod else { // `SKProduct.subscriptionPeriod` can be non-nil for products that do not represent subscriptions, so we add in our own check here
            return nil
        }
        
        let period: SubscriptionPeriod = subscriptionPeriod(from: skSubscriptionPeriod)
        
        let introductoryOffer: SubscriptionTerms.IntroductoryOffer? = {
            if let skDiscount = self.source.skProduct.introductoryPrice {
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
    internal enum Source : Hashable {
        case availableProduct(SKProduct)
        case pendingStorePayment(SKProduct, SKPayment)
        
        var skProduct: SKProduct {
            switch self {
                case .availableProduct(let product):
                    return product
                case .pendingStorePayment(let product, _):
                    return product
            }
        }
    }
    
    /// This type is not intended to ever be publicly exposed. It carries file-private metadata.
    private struct Characteristics : OptionSet, Hashable {
        let rawValue: UInt
        
        init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        
        static let isSubscription: Characteristics = Characteristics(rawValue: 1 << 1)
        static let isAutorenewingSubscription: Characteristics = Characteristics(rawValue: 1 << 2)
    }
}
