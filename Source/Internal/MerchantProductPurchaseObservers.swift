extension Merchant {
    internal class StorePurchaseObservers {
        internal private(set) var purchaseProducts = ObserverSet<PurchaseProductsObserver>()
        internal private(set) var restorePurchasedProducts = ObserverSet<RestorePurchasedProductsObserver>()

        internal init() {
            
        }

        internal func observers<T>(for keyPath: KeyPath<StorePurchaseObservers, ObserverSet<T>>) -> [T] {
            return self[keyPath: keyPath].elements
        }

        internal func add<T>(_ observer: T, forObserving keyPath: KeyPath<StorePurchaseObservers, ObserverSet<T>>) {
            self[keyPath: (keyPath as! ReferenceWritableKeyPath)].insert(observer)
        }

        internal func remove<T>(_ observer: T, forObserving keyPath: KeyPath<StorePurchaseObservers, ObserverSet<T>>) {
            self[keyPath: (keyPath as! ReferenceWritableKeyPath)].remove(observer)
        }

        // prolly don't want to use `KeyPath` as parameters long-term but there isn't a better way to express this with generic constraints yet

        // properly nest these protocols when Swift lets us
        typealias PurchaseProductsObserver = MerchantStorePurchaseObserversPurchaseProductsObserver
        typealias RestorePurchasedProductsObserver = MerchantStorePurchaseObserversRestorePurchasedProductsObserver

        internal struct ObserverSet<T> {
            private var _elements = Set<IdentityWrapper>()
            
            fileprivate mutating func insert(_ element: T) {
                self._elements.insert(IdentityWrapper(element))
            }
            
            fileprivate mutating func remove(_ element: T) {
                self._elements.remove(IdentityWrapper(element))
            }
            
            fileprivate var elements: [T] {
                return self._elements.map { $0.element as! T }
            }
        }
    }
}

// nest in `MerchantStorePurchaseObservers` when Swift lets us
internal protocol MerchantStorePurchaseObserversPurchaseProductsObserver : AnyObject {
    func merchant(_ merchant: Merchant, didFinishPurchaseWith result: Result<Void, Error>, forProductWith productIdentifier: String)
}

// nest in `MerchantStorePurchaseObservers` when Swift lets us
internal protocol MerchantStorePurchaseObserversRestorePurchasedProductsObserver : AnyObject {
    func merchantDidStartRestoringProducts(_ merchant: Merchant)

    func merchant(_ merchant: Merchant, didRestorePurchasedProductWith productIdentifier: String)
    
    func merchant(_ merchant: Merchant, didFinishRestoringProductsWith result: Result<Void, Error>)
}

extension Merchant.StorePurchaseObservers {
    private struct IdentityWrapper : Hashable {
        internal let element: AnyObject
        
        init<T>(_ element: T) {
            self.element = element as AnyObject
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(self.element))
        }
        
        static func ==(lhs: IdentityWrapper, rhs: IdentityWrapper) -> Bool {
            return lhs.element === rhs.element
        }
    }
}
