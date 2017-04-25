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
    
    fileprivate var purchaseObservers = [String : [MerchantPurchaseObserver]]()
    
    public init(delegate: MerchantDelegate) {
        self.delegate = delegate
        self.storage = UserDefaultsPurchaseStorage()
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
    
    /// Find possible purchases for the given product identifiers. If `productIdentifiers` is empty, then the merchant looks up all purchases for all registered products.
    public func availablePurchasesTask(forProductIdentifiers productIdentifiers: Set<String> = []) -> AvailablePurchasesTask {
        return self.makeTask(initializing: {
            let task = AvailablePurchasesTask(forProductIdentifiers: productIdentifiers, with: self)
    
            return task
        })
    }
    
    /// Begin buying a specific purchase.
    public func commitPurchaseTask(for purchase: Purchase) -> CommitPurchaseTask {
        return self.makeTask(initializing: {
            let task = CommitPurchaseTask(for: purchase, with: self)
            
            return task 
        })
    }
}

extension Merchant {
    internal var registeredProducts: Set<Product> { // TODO: Consider making this public API
        return Set(self._registeredProducts.values)
    }
    
    func addPurchaseObserver(_ observer: MerchantPurchaseObserver, forProductIdentifier productIdentifier: String) {
        var observers = self.purchaseObservers[productIdentifier] ?? []
        
        if !observers.contains(where: { $0 === observer }) {
            observers.append(observer)
        }
        
        self.purchaseObservers[productIdentifier] = observers
    }
    
    func removePurchaseObserver(_ observer: MerchantPurchaseObserver, forProductIdentifier productIdentifier: String) {
        if var observers = self.purchaseObservers[productIdentifier] {
            if let index = observers.index(where: { $0 === observer }) {
                observers.remove(at: index)
            }
            
            self.purchaseObservers[productIdentifier] = observers
        }
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
    fileprivate func checkReceipt() {
        if let url = Bundle.main.appStoreReceiptURL, let data = try? Data(contentsOf: url) {
            self.validateReceipt(with: data)
        } else {
            self.refreshReceipt()
        }
    }
    
    fileprivate func validateReceipt(with data: Data) {
        self.delegate.merchant(self, validate: data, completion: { result in
            switch result {
                case .succeeded(let receipt):
                    self.updateStorageFrom(receipt)
                case .failed(let error):
                    print(error)
            }
        })
    }
    
    fileprivate func refreshReceipt() {
        fatalError("not yet implemented")
    }
    
    fileprivate func updateStorageFrom(_ receipt: Receipt) {
        var updatedProducts = Set<Product>()
        
        for identifier in receipt.productIdentifiers {
            let entries = receipt.entries(forProductIdentifier: identifier)
            
            let isPurchased = !entries.isEmpty
            let expiryDate = entries.flatMap { $0.expiryDate }.max()
            
            let record = PurchaseRecord(productIdentifier: identifier, expiryDate: expiryDate, isPurchased: isPurchased)
            
            let result = self.storage.save(record)
            
            if result == .didChangeRecords, let product = self._registeredProducts[identifier] {
                updatedProducts.insert(product)
            }
        }
        
        self.didChangeState(for: updatedProducts)
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
        print(record)
        let result = self.storage.save(record)
        
        if result == .didChangeRecords {
            self.didChangeState(for: [product])
        }
        
        for observer in self.purchaseObservers[product.identifier] ?? [] {
            observer.merchant(self, didCompletePurchaseForProductWith: product.identifier)
        }
    }
    
    func storeKitTransactionObserver(_ observer: StoreKitTransactionObserver, didFailToPurchaseWith error: Error, forProductWith identifier: String) {
        for observer in self.purchaseObservers[identifier] ?? [] {
            observer.merchant(self, didFailPurchaseWith: error, forProductWith: identifier)
        }
    }
}
