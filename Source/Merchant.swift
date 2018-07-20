import Foundation
import StoreKit

/// The `Merchant` manages a set of registered products. The `Merchant` creates tasks to perform various operations, and tracks the `PurchasedState` of products.
/// There will typically be only one `Merchant` instantiated in an application.
public final class Merchant {
    /// The `delegate` will be called to respond to various events.
    public let delegate: MerchantDelegate
    
    /// The parameters to forward onto the underlying `StoreKit` framework. These parameters apply to all transactions handled by the `Merchant`.
    public var storeParameters: StoreParameters = StoreParameters()
    
    /// The application may want to display some (non-blocking) UI when the `Merchant` is loading. This property represents activity from the `Merchant` and derived tasks. The `delegate` is notified when this property changes.
    public private(set) var isLoading: Bool = false
    
    /// `Merchant` will optionally record various logging events using the system `os_log`. These events can be filtered in the Console application, but are unfortunately hard to ignore inside Xcode itself. Defaults to `false`.
    public var canGenerateLogs: Bool {
        get {
            return self.logger.isActive
        }
        set {
            self.logger.isActive = newValue
        }
    }
    
    internal let logger = Logger()
    
    private let storage: PurchaseStorage
    private let transactionObserver: StoreKitTransactionObserver = StoreKitTransactionObserver()
    
    private var _registeredProducts: [String : Product] = [:]
    private var activeTasks: [MerchantTask] = []
    
    private var purchaseObservers: Buckets<String, MerchantPurchaseObserver> = Buckets()
    
    private var receiptFetchers: [ReceiptFetchPolicy : ReceiptDataFetcher] = [:]
    private var receiptDataFetcherCustomInitializer: ReceiptDataFetcherInitializer?
    private var identifiersForPendingObservedPurchases: Set<String> = []
    
    private let nowDate: Date = Date()
    private var latestFetchedReceipt: Receipt?
    
    /// Create a `Merchant`, probably at application launch. Assign a consistent `storage` and a `delegate` to receive callbacks.
    public init(storage: PurchaseStorage, delegate: MerchantDelegate) {
        self.delegate = delegate
        self.storage = storage
    }
    
    /// Products must be registered before their states are consistently valid. Products should be registered as early as possible.
    /// See `LocalConfiguration` for a basic way to register products using a locally stored file.
    public func register<Products : Sequence>(_ products: Products) where Products.Iterator.Element == Product {
        for product in products {
            self._registeredProducts[product.identifier] = product
        }
    }
    
    /// Call this method at application launch. It performs necessary initialization routines.
    public func setup() {
        self.beginObservingTransactions()
        
        self.checkReceipt(updateProducts: .all, policy: .onlyFetch, reason: .initialization)
    }
    
    /// Returns a registered product for a given `productIdentifier`, or `nil` if not found.
    public func product(withIdentifier productIdentifier: String) -> Product? {
        return self._registeredProducts[productIdentifier]
    }
    
    /// Returns the state for a `product`. Consumable products always report that they are `notPurchased`.
    public func state(for product: Product) -> PurchasedState {
        guard let record = self.storage.record(forProductIdentifier: product.identifier) else {
            return .notPurchased
        }
        
        switch product.kind {
            case .consumable:
                return .notPurchased
            case .nonConsumable, .subscription(automaticallyRenews: _):
                let info = PurchasedProductInfo(expiryDate: record.expiryDate)
            
                return .isPurchased(info)
        }
    }
    
    /// Find possible purchases for the given products. If `products` is empty, then the merchant looks up all purchases for all registered products.
    public func availablePurchasesTask(for products: Set<Product> = []) -> AvailablePurchasesTask {
        return self.makeTask(initializing: {
            let products = products.isEmpty ? Set(self._registeredProducts.values) : products
            
            let task = AvailablePurchasesTask(for: products, with: self)
    
            return task
        })
    }
    
    /// Begin buying a product, supplying a `purchase` fetched from the `AvailablePurchasesTask`.
    public func commitPurchaseTask(for purchase: Purchase) -> CommitPurchaseTask {
        return self.makeTask(initializing: {
            let task = CommitPurchaseTask(for: purchase, with: self)
            
            return task 
        })
    }
    
    /// Restore the user's purchases. Calling this method may present modal UI.
    public func restorePurchasesTask() -> RestorePurchasesTask {
        return self.makeTask(initializing: {
            let task = RestorePurchasesTask(with: self)
            
            return task
        })
    }
}

// MARK: Testing hooks
extension Merchant {
    typealias ReceiptDataFetcherInitializer = (ReceiptFetchPolicy) -> ReceiptDataFetcher
    
    /// Allows tests in the test suite to change the receipt data fetcher that is created.
    internal func setCustomReceiptDataFetcherInitializer(_ initializer: @escaping ReceiptDataFetcherInitializer) {
        self.receiptDataFetcherCustomInitializer = initializer
    }
}

// MARK: Purchase observers
extension Merchant {
    internal func addPurchaseObserver(_ observer: MerchantPurchaseObserver, forProductIdentifier productIdentifier: String) {
        var observers = self.purchaseObservers[productIdentifier]
        
        if !observers.contains(where: { $0 === observer }) {
            observers.append(observer)
        }
        
        self.purchaseObservers[productIdentifier] = observers
    }
    
    internal func removePurchaseObserver(_ observer: MerchantPurchaseObserver, forProductIdentifier productIdentifier: String) {
        var observers = self.purchaseObservers[productIdentifier]
        
        if let index = observers.index(where: { $0 === observer }) {
            observers.remove(at: index)
            
            self.purchaseObservers[productIdentifier] = observers
        }
    }
}

// MARK: Task management
extension Merchant {
    private func makeTask<Task : MerchantTask>(initializing creator: () -> Task) -> Task {
        let task = creator()
        
        self.addActiveTask(task)
        
        return task
    }
    
    private func addActiveTask(_ task: MerchantTask) {
        self.activeTasks.append(task)
        self.updateLoadingStateIfNecessary()
    }
    
    // Call on main thread only.
    internal func updateActiveTask(_ task: MerchantTask) {
        self.updateLoadingStateIfNecessary()
    }
    
    // Call on main thread only.
    internal func resignActiveTask(_ task: MerchantTask) {
        guard let index = self.activeTasks.index(where: { $0 === task }) else { return }
        
        self.activeTasks.remove(at: index)
        self.updateLoadingStateIfNecessary()
    }
}

// MARK: Loading state changes
extension Merchant {
    private var _isLoading: Bool {
        return !self.activeTasks.filter { $0.isStarted }.isEmpty || !self.receiptFetchers.isEmpty
    }
    
    /// Call on main thread only.
    private func updateLoadingStateIfNecessary() {
        let isLoading = self.isLoading
        let updatedIsLoading = self._isLoading
        
        if updatedIsLoading != isLoading {
            self.isLoading = updatedIsLoading
            
            self.delegate.merchantDidChangeLoadingState(self)
        }
    }
}

// MARK: Subscription utilities
extension Merchant {
    private func isSubscriptionActive(forExpiryDate expiryDate: Date) -> Bool {
        let leeway: TimeInterval = 60 // 60 * 60 * 24
        
        return expiryDate.addingTimeInterval(leeway) > self.nowDate
    }
}

// MARK: Payment queue related behaviour
extension Merchant {
    private func beginObservingTransactions() {
        self.transactionObserver.delegate = self
        
        SKPaymentQueue.default().add(self.transactionObserver)
    }
    
    private func stopObservingTransactions() {
        SKPaymentQueue.default().remove(self.transactionObserver)
    }
    
    // Right now, Merchant relies on refreshing receipts to restore purchases. The implementation may be changed in future.
    internal func restorePurchases(completion: @escaping CheckReceiptCompletion) {
        self.checkReceipt(updateProducts: .all, policy: .alwaysRefresh, reason: .restorePurchases, completion: completion)
    }
}

// MARK: Receipt fetch and validation
extension Merchant {
    internal typealias CheckReceiptCompletion = (_ updatedProducts: Set<Product>, Error?) -> Void
    
    private func checkReceipt(updateProducts updateType: ReceiptUpdateType, policy: ReceiptFetchPolicy, reason: ReceiptValidationRequest.Reason, completion: @escaping CheckReceiptCompletion = { _,_ in }) {
        let fetcher: ReceiptDataFetcher
        let isStarted: Bool
        
        if let activeFetcher = self.receiptFetchers[policy] { // the same fetcher may be pooled and used multiple times, this is because `enqueueCompletion` can add blocks even after the fetcher has been started
            fetcher = activeFetcher
            isStarted = true
            
            self.logger.log(message: "Reused receipt fetcher for \(policy)", category: .receipt)
        } else {
            fetcher = self.makeFetcher(for: policy)
            isStarted = false
            
            self.receiptFetchers[policy] = fetcher
            self.logger.log(message: "Created receipt fetcher for \(policy)", category: .receipt)
        }
        
        fetcher.enqueueCompletion { [weak self] dataResult in
            guard let strongSelf = self else { return }
            
            switch dataResult {
                case .succeeded(let receiptData):
                    strongSelf.logger.log(message: "Receipt fetch succeeded: found \(receiptData.count) bytes", category: .receipt)
                    
                    strongSelf.validateReceipt(with: receiptData, reason: reason, completion: { [weak self] validateResult in
                        guard let strongSelf = self else { return }
                        
                        switch validateResult {
                            case .succeeded(let receipt):
                                strongSelf.logger.log(message: "Receipt validation succeeded: \(receipt)", category: .receipt)
                                
                                strongSelf.latestFetchedReceipt = receipt
                                
                                let updatedProducts = strongSelf.updateStorageWithValidatedReceipt(receipt, updateProducts: updateType)
                            
                                if !updatedProducts.isEmpty {
                                    DispatchQueue.main.async {
                                        strongSelf.didChangeState(for: updatedProducts)
                                    }
                                }
                                
                                completion(updatedProducts, nil)
                            case .failed(let error):
                                strongSelf.logger.log(message: "Receipt validation failed: \(error)", category: .receipt)

                                completion([], error)
                        }
                    })
                case .failed(let error):
                    strongSelf.logger.log(message: "Receipt fetch failed: \(error)", category: .receipt)

                    completion([], error)
            }
            
            strongSelf.receiptFetchers.removeValue(forKey: policy)
            
            if strongSelf.receiptFetchers.isEmpty && strongSelf.isLoading {
                DispatchQueue.main.async {
                    strongSelf.updateLoadingStateIfNecessary()
                }
            }
        }
        
        if !isStarted {
            fetcher.start()
            
            if !self.receiptFetchers.isEmpty && !self.isLoading {
                self.updateLoadingStateIfNecessary()
            }
        }
    }
    
    private func makeFetcher(for policy: ReceiptFetchPolicy) -> ReceiptDataFetcher {
        if let initializer = self.receiptDataFetcherCustomInitializer {
            return initializer(policy)
        }
        
        return StoreKitReceiptDataFetcher(policy: policy)
    }
    
    private func validateReceipt(with data: Data, reason: ReceiptValidationRequest.Reason, completion: @escaping (Result<Receipt>) -> Void) {
        DispatchQueue.main.async {
            let request = ReceiptValidationRequest(data: data, reason: reason)
            
            self.delegate.merchant(self, validate: request, completion: completion)
        }
    }
    
    private func updateStorageWithValidatedReceipt(_ receipt: Receipt, updateProducts updateType: ReceiptUpdateType) -> Set<Product> {
        var updatedProducts = Set<Product>()
        let productIdentifiers: Set<String>
        
        switch updateType {
            case .all:
                productIdentifiers = receipt.productIdentifiers
            case .specific(let identifiers):
                productIdentifiers = identifiers
        }
        
        for productIdentifier in productIdentifiers {
            guard let product = self.product(withIdentifier: productIdentifier) else { continue }
            guard product.kind != .consumable else { continue } // consumables are special-cased as they are not recorded, but may temporarily appear in receipts
            
            let entries = receipt.entries(forProductIdentifier: productIdentifier)
            
            let hasEntry = !entries.isEmpty
            
            let result: PurchaseStorageUpdateResult
            
            if hasEntry {
                let expiryDate = entries.compactMap { $0.expiryDate }.max()
                
                if let expiryDate = expiryDate, !self.isSubscriptionActive(forExpiryDate: expiryDate) {
                    result = self.storage.removeRecord(forProductIdentifier: productIdentifier)
                    
                    self.logger.log(message: "Removed record for \(productIdentifier), given expiry date \(expiryDate)", category: .purchaseStorage)
                } else {
                    let record = PurchaseRecord(productIdentifier: productIdentifier, expiryDate: expiryDate)
                
                    result = self.storage.save(record)
                    
                    self.logger.log(message: "Saved record: \(record)", category: .purchaseStorage)
                }
            } else {
                result = self.storage.removeRecord(forProductIdentifier: productIdentifier)
                
                self.logger.log(message: "Removed record for \(productIdentifier)", category: .purchaseStorage)
            }
            
            if result == .didChangeRecords {
                updatedProducts.insert(product)
            }
        }
        
        if updateType == .all { // clean out from storage if registered products are not in the receipt
            let registeredProductIdentifiers = Set(self._registeredProducts.map { $0.key })
            let identifiersForProductsNotInReceipt = registeredProductIdentifiers.subtracting(receipt.productIdentifiers)
            
            for productIdentifier in identifiersForProductsNotInReceipt {
                let result = self.storage.removeRecord(forProductIdentifier: productIdentifier)
                self.logger.log(message: "Removed record for \(productIdentifier): product not in receipt", category: .purchaseStorage)

                if result == .didChangeRecords {
                    updatedProducts.insert(self._registeredProducts[productIdentifier]!)
                }
            }
        }
        
        return updatedProducts
    }
    
    private enum ReceiptUpdateType : Equatable {
        case all
        case specific(productIdentifiers: Set<String>)
    }
}

// MARK: Product state changes
extension Merchant {
    /// Call on main thread only.
    private func didChangeState(for products: Set<Product>) {
        self.delegate.merchant(self, didChangeStatesFor: products)
    }
}

// MARK: `StoreKitTransactionObserverDelegate` Conformance
extension Merchant : StoreKitTransactionObserverDelegate {
    internal func storeKitTransactionObserverWillUpdatePurchases(_ observer: StoreKitTransactionObserver) {
        
    }
    
    internal func storeKitTransactionObserver(_ observer: StoreKitTransactionObserver, didPurchaseProductWith identifier: String) {
        if let product = self.product(withIdentifier: identifier) {
            if product.kind == .consumable { // consumable product purchases are not recorded
                self.delegate.merchant(self, didConsume: product)
            } else { // non-consumable and subscription products are recorded
                let record = PurchaseRecord(productIdentifier: identifier, expiryDate: nil)
                let result = self.storage.save(record)
            
                if result == .didChangeRecords {
                    self.didChangeState(for: [product])
                }
                
                if case .subscription(_) = product.kind {
                    self.identifiersForPendingObservedPurchases.insert(product.identifier) // we need to get the receipt to find the expiry date, the `PurchaseRecord` will be updated when that information is available
                }
            }
        }
        
        for observer in self.purchaseObservers[identifier] {
            observer.merchant(self, didCompletePurchaseForProductWith: identifier)
        }
    }
    
    internal func storeKitTransactionObserver(_ observer: StoreKitTransactionObserver, didFailToPurchaseWith error: Error, forProductWith identifier: String) {
        for observer in self.purchaseObservers[identifier] {
            observer.merchant(self, didFailPurchaseWith: error, forProductWith: identifier)
        }
    }
    
    internal func storeKitTransactionObserverDidUpdatePurchases(_ observer: StoreKitTransactionObserver) {
        if !self.identifiersForPendingObservedPurchases.isEmpty {
            self.logger.log(message: "Invoked receipt update for purchases \(self.identifiersForPendingObservedPurchases)", category: .receipt)

            self.checkReceipt(updateProducts: .specific(productIdentifiers: self.identifiersForPendingObservedPurchases), policy: .onlyFetch, reason: .completePurchase, completion: { _, _ in })
        }
        
        self.identifiersForPendingObservedPurchases.removeAll()
    }
}
