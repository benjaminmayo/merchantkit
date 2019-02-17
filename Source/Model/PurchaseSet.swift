/// A collection of unique `Purchase` objects. This set is vended by an `AvailablePurchasesTask`.
public struct PurchaseSet : Equatable {
    private let storage: [String : Purchase]
    
    internal init<Purchases : Sequence>(from purchases: Purchases) where Purchases.Iterator.Element == Purchase {
        var storage = [String : Purchase]()
        
        for purchase in purchases {
            storage[purchase.productIdentifier] = purchase
        }
        
        self.storage = storage
    }
    
    /// Returns the purchase for a given product, if it exists.
    public func purchase(for product: Product) -> Purchase? {
        return self.storage[product.identifier]
    }
    
    /// Returns an `Array` of all purchases sorted by their price.
    /// If `ascending` is true, purchases returned from cheapest to most expensive.
    /// If `ascending` is false, purchases returned from most expensive to cheapest.
    public func sortedByPrice(ascending: Bool) -> [Purchase] {
        return self.storage.values.sorted(by: { a, b in
            let aPrice = a.price.value.0
            let bPrice = b.price.value.0
            
            let comparator: (Decimal, Decimal) -> Bool = ascending ? (<) : (>)
            
            return comparator(aPrice, bPrice)
        })
    }
}

extension PurchaseSet : Sequence {
    public var underestimatedCount: Int {
        return self.storage.count
    }
    
    public func makeIterator() -> AnyIterator<Purchase> {
        return AnyIterator(self.storage.values.makeIterator())
    }
}
