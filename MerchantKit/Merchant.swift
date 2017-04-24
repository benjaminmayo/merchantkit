import Foundation
import StoreKit

public protocol MerchantDelegate : class {
    func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>)
    func merchant(_ merchant: Merchant, validate receiptData: Data, completion: @escaping (_ result: Result<Receipt>) -> Void)
}

public final class Merchant {
    public let delegate: MerchantDelegate
    
    fileprivate let storage: PurchaseStorage
    private let transactionObserver = StoreKitTransactionObserver()
    
    fileprivate var _registeredProducts = [String : Product]() // TODO: Consider alternative data structure
    fileprivate var activeTasks = [MerchantTask]()
    
    public init(delegate: MerchantDelegate) {
        self.delegate = delegate
        self.storage = UserDefaultsPurchaseStorage()
    }
    
    internal var registeredProducts: Set<Product> { // TODO: Consider making this public API
        return Set(self._registeredProducts.values)
    }
    
    public func register<Products : Sequence>(_ products: Products) where Products.Iterator.Element == Product {
        for product in products {
            self._registeredProducts[product.identifier] = product
        }
    }
    
    public func beginObservingTransactions() {
        self.transactionObserver.delegate = self
        
        SKPaymentQueue.default().add(self.transactionObserver)
    }
    
    public func state(forProductWithIdentifier productIdentifier: String) -> PurchasedState {
        guard let product = self._registeredProducts[productIdentifier] else {
            return .unknown
        }
        
        guard let record = self.storage.record(forProductIdentifier: productIdentifier) else {
            return .unknown
        }
        
        switch product.kind {
            case .consumable:
                fatalError("consumable support not yet implemented")
            case .nonConsumable:
                if record.isPurchased {
                    return .isConsumable
                } else {
                    return .notPurchased
                }
            case .subscription(_):
                let now = Date()
                
                if let expiryDate = record.expiryDate, expiryDate > now {
                    return .isSubscribed(expiryDate: expiryDate)
                } else if record.isPurchased {
                    return .isSubscribed(expiryDate: nil)
                } else {
                    return .notPurchased
                }
        }
    }
    
    public func availablePurchasesTask() -> AvailablePurchasesTask {
        return self.makeTask(initializing: {
            let task = AvailablePurchasesTask(for: self)
    
            return task
        })
    }
}

extension Merchant {
    fileprivate func makeTask<Task : MerchantTask>(initializing creator: () -> Task) -> Task {
        let task = creator()
        
        self.addActiveTask(task)
        
        return task
    }
    
    private func addActiveTask(_ task: MerchantTask) {
        self.activeTasks.append(task)
    }
    
    internal func resignActiveTask(_ task: MerchantTask) {
        guard let index = self.activeTasks.index(where: { $0 === task }) else { return }
        
        self.activeTasks.remove(at: index)
    }
}

extension Merchant {
    fileprivate func didChangeState(for products: Set<Product>) {
        self.delegate.merchant(self, didChangeStatesFor: products)
    }
}

extension Merchant : StoreKitTransactionObserverDelegate {
    internal func storeKitTransactionObserver(_ observer: StoreKitTransactionObserver, didPurchaseProductWith identifier: String) {
        guard let product = self._registeredProducts[identifier] else { print("unrecognized product identifier"); return } // TODO: Consider error handling
        
        guard product.kind == .nonConsumable else { print(product.kind, "not supported via storekit observation"); return } // TODO: Implement consumable support, Decide correct flow for subscription products
        
        let record = PurchaseRecord(productIdentifier: identifier, expiryDate: nil, isPurchased: true)
        let result = self.storage.save(record)
        
        if result == .didChangeRecords {
            self.didChangeState(for: [product])
        }
    }
}
