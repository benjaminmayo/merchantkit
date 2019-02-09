import Foundation
import StoreKit

/// The `Merchant` manages a set of registered products. The `Merchant` creates tasks to perform various operations, and tracks the `PurchasedState` of products.
/// There will typically be only one `Merchant` instantiated in an application.
public final class Merchant {
    /// The `delegate` will be called to respond to various events.
    public let delegate: MerchantDelegate?
    
    // The `consumableHandler` will be used if, and only if, you use the `Merchant` to try and purchase consumable products. It is not required otherwise.
    public let consumableHandler: MerchantConsumableProductHandler!
    
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
    
    private let configuration: Configuration
    
    private let transactionObserver: StoreKitTransactionObserver = StoreKitTransactionObserver()
    
    private var _registeredProducts: [String : Product] = [:]
    private var activeTasks: [MerchantTask] = []
    
    private var purchaseObservers = [MerchantPurchaseObserver]()
    private var hasSetup: Bool = false
    
    private var receiptFetchers: [ReceiptFetchPolicy : ReceiptDataFetcher] = [:]
    private var receiptDataFetcherCustomInitializer: ReceiptDataFetcherInitializer?
    private var identifiersForPendingObservedPurchases: Set<String> = []
    
    private let nowDate: Date = Date()
    internal var latestFetchedReceipt: Receipt?
    
    /// Create a `Merchant` as part of application launch lifecycle. Use `Merchant.Configuration.default` for an appropriate default setup, or you can supply your own customized `Merchant.Configuration`.
    /// The `delegate` is optional, but you may want to use it to be globally alerted to changes in state. You can always ask for the current purchased state of a `Product` using `Merchant.state(for:)`.
    /// The `consumableHandler` is **required** if your application uses consumable products.
    public init(configuration: Configuration, delegate: MerchantDelegate? = nil, consumableHandler: MerchantConsumableProductHandler? = nil) {
        self.configuration = configuration
        self.delegate = delegate
        self.consumableHandler = consumableHandler
    }
    
    @available(*, unavailable, message: "This initializer has been removed. Use `Merchant.init(configuration:delegate:consumableHandler:)`, likely passing a `.default` configuration as the first parameter — `delegate` and `consumableHandler` are optional. You will need to migrate `Merchant` and your `MerchantDelegate` conformance to the new API.")
    public init(storage: PurchaseStorage, delegate: MerchantDelegate) {
        fatalError("Merchant.init(storage:delegate:) initializer is no longer supported. Please switch to Merchant.init(configuration:delegate:consumableHandler:)")
    }
    
    /// Register products that you want to use in your application. Products must be registered before their states are consistently valid. Products should be registered as early as possible, typically just before calling `setup()`.
    public func register<Products : Sequence>(_ products: Products) where Products.Iterator.Element == Product {
        for product in products {
            self._registeredProducts[product.identifier] = product
        }
    }
    
    /// Call this method at application launch. It performs necessary initialization routines.
    public func setup() {
        guard !self.hasSetup else { return }
        self.hasSetup = true
        
        self.beginObservingTransactions()
        
        self.checkReceipt(updateProducts: .all, policy: .onlyFetch, reason: .initialization)
        
        self.logger.log(message: "Merchant has been setup, with \(self._registeredProducts.count) registered \(self._registeredProducts.count == 1 ? "product" : "products").", category: .initialization)
    }
    
    /// Returns a registered product for a given `productIdentifier`, or `nil` if not found.
    public func product(withIdentifier productIdentifier: String) -> Product? {
        return self._registeredProducts[productIdentifier]
    }
    
    /// Returns the state for a `product`. Consumable products always report that they are `notPurchased`.
    public func state(for product: Product) -> PurchasedState {
        guard let record = self.configuration.storage.record(forProductIdentifier: product.identifier) else {
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
    
    /// Find possible purchases for the given products. If `products` is empty, then the zMerchantz finds purchases for all registered products.
    public func availablePurchasesTask(for products: Set<Product> = []) -> AvailablePurchasesTask {
        self.ensureSetup()
        
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
    
    /// Get local app receipt metadata, if available.
    public func receiptMetadataTask() -> ReceiptMetadataTask {
        return self.makeTask(initializing: {
            let task = ReceiptMetadataTask(with: self)
            
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
    internal func addPurchaseObserver(_ observer: MerchantPurchaseObserver) {
        if !self.purchaseObservers.contains(where: { $0 === observer }) {
            self.purchaseObservers.append(observer)
        }
    }
    
    internal func removePurchaseObserver(_ observer: MerchantPurchaseObserver) {
        if let index = self.purchaseObservers.index(where: { $0 === observer }) {
            self.purchaseObservers.remove(at: index)
        }
    }
}

// MARK: Task management
extension Merchant {
    private func makeTask<Task : MerchantTask>(initializing creator: () -> Task) -> Task {
        let task = creator()
        
        self.activeTasks.append(task)
        
        return task
    }
    
    // Call on main thread only.
    internal func taskDidStart(_ task: MerchantTask) {
        self.updateLoadingStateIfNecessary()
    }
    
    // Call on main thread only.
    internal func taskDidResign(_ task: MerchantTask) {
        guard let index = self.activeTasks.index(where: { $0 === task }) else { return }
        
        self.activeTasks.remove(at: index)
        self.updateLoadingStateIfNecessary()
    }
}

// MARK: Loading state changes
extension Merchant {
    private var _isLoading: Bool {
        let hasActiveTasks = self.activeTasks.contains(where: { $0.isStarted })
        let hasActiveReceiptFetchers = !self.receiptFetchers.isEmpty
        
        return hasActiveTasks || hasActiveReceiptFetchers
    }
    
    /// Call on main thread only.
    private func updateLoadingStateIfNecessary() {
        let isLoading = self.isLoading
        let updatedIsLoading = self._isLoading
        
        if updatedIsLoading != isLoading {
            self.isLoading = updatedIsLoading
            
            self.delegate?.merchantDidChangeLoadingState(self)
        }
    }
}

// MARK: Subscription utilities
extension Merchant {
    private func isSubscriptionActive(forExpiryDate expiryDate: Date) -> Bool {
        let leeway: TimeInterval = 60 // one minute of leeway, could make this a configurable setting in future
        
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
    
    // Warns users if `Merchant` has not been correctly configured.
    private func ensureSetup() {
        guard !self.hasSetup else { return }
        
        // Print the warning to the console. As this is a serious usage error, we do not route it through the optional framework logging.
        print("Merchant is attempting to vend purchases, but the Merchant has not been setup. Remember to call `Merchant.setup()` during application launch.")
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
            guard let self = self else { return }
            
            switch dataResult {
                case .succeeded(let receiptData):
                    self.logger.log(message: "Receipt fetch succeeded: found \(receiptData.count) bytes", category: .receipt)
                    
                    self.validateReceipt(with: receiptData, reason: reason, completion: { [weak self] validateResult in
                        guard let self = self else { return }
                        
                        switch validateResult {
                            case .succeeded(let receipt):
                                self.logger.log(message: "Receipt validation succeeded: \(receipt)", category: .receipt)
                                
                                self.latestFetchedReceipt = receipt
                                
                                let updatedProducts = self.updateStorageWithValidatedReceipt(receipt, updateProducts: updateType)
                            
                                if !updatedProducts.isEmpty {
                                    DispatchQueue.main.async {
                                        self.didChangeState(for: updatedProducts)
                                    }
                                }
                                
                                completion(updatedProducts, nil)
                            case .failed(let error):
                                self.logger.log(message: "Receipt validation failed: \(error)", category: .receipt)

                                completion([], error)
                        }
                    })
                case .failed(let error):
                    self.logger.log(message: "Receipt fetch failed: \(error)", category: .receipt)

                    completion([], error)
            }
            
            self.receiptFetchers.removeValue(forKey: policy)
            
            if self.receiptFetchers.isEmpty && self.isLoading {
                DispatchQueue.main.async {
                    self.updateLoadingStateIfNecessary()
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
        let request = ReceiptValidationRequest(data: data, reason: reason)
        
        self.configuration.receiptValidator.validate(request, completion: completion)
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
                    result = self.configuration.storage.removeRecord(forProductIdentifier: productIdentifier)
                    
                    self.logger.log(message: "Removed record for \(productIdentifier), given expiry date \(expiryDate)", category: .purchaseStorage)
                } else {
                    let record = PurchaseRecord(productIdentifier: productIdentifier, expiryDate: expiryDate)
                
                    result = self.configuration.storage.save(record)
                    
                    self.logger.log(message: "Saved record: \(record)", category: .purchaseStorage)
                }
            } else {
                result = self.configuration.storage.removeRecord(forProductIdentifier: productIdentifier)
                
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
                let result = self.configuration.storage.removeRecord(forProductIdentifier: productIdentifier)
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
        self.delegate?.merchant(self, didChangeStatesFor: products)
    }
}

// MARK: `StoreKitTransactionObserverDelegate` Conformance
extension Merchant : StoreKitTransactionObserverDelegate {
    internal func storeKitTransactionObserverWillUpdatePurchases(_ observer: StoreKitTransactionObserver) {
        
    }
    
    internal func storeKitTransactionObserver(_ observer: StoreKitTransactionObserver, didPurchaseProductWith identifier: String, completion: @escaping () -> Void) {
        func didCompletePurchase() {
            completion()
        }
        
        if let product = self.product(withIdentifier: identifier) {
            if product.kind == .consumable { // consumable product purchases are not recorded
                guard let consumableHandler = self.consumableHandler else {
                    MerchantKitFatalError.raise("`Merchant` tried to purchase a consumable product but the `Merchant.consumableHandler` was not set. You must provide a `consumbleHandler` when you instantiate the `Merchant` to handle consumables.")
                }
                
                consumableHandler.merchant(self, consume: product, completion: didCompletePurchase)
            } else { // non-consumable and subscription products are recorded
                let record = PurchaseRecord(productIdentifier: identifier, expiryDate: nil)
                let result = self.configuration.storage.save(record)
            
                if result == .didChangeRecords {
                    self.didChangeState(for: [product])
                }
                
                if case .subscription(_) = product.kind {
                    self.identifiersForPendingObservedPurchases.insert(product.identifier) // we need to get the receipt to find the expiry date, the `PurchaseRecord` will be updated when that information is available
                }
                
                didCompletePurchase()
            }
        }
        
        for observer in self.purchaseObservers {
            observer.merchant(self, didCompletePurchaseForProductWith: identifier)
        }
    }
    
    internal func storeKitTransactionObserver(_ observer: StoreKitTransactionObserver, didFailToPurchaseWith error: Error, forProductWith identifier: String) {
        for observer in self.purchaseObservers {
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
    
    internal func storeKitTransactionObserver(_ observer: StoreKitTransactionObserver, didFinishRestoringPurchasesWith error: Error?) {
        for observer in self.purchaseObservers {
            observer.merchant(self, didCompleteRestoringPurchasesWith: error)
        }
    }
    
    internal func storeKitTransactionObserver(_ observer: StoreKitTransactionObserver, purchaseFor source: Purchase.Source) -> Purchase? {
        guard let product = self.product(withIdentifier: source.skProduct.productIdentifier) else { return nil }
        
        return Purchase(from: source, for: product)
    }
    
    internal func storeKitTransactionObserver(_ observer: StoreKitTransactionObserver, responseForStoreIntentToCommit purchase: Purchase) -> StoreIntentResponse {
        let intent = self.delegate?.merchant(self, didReceiveStoreIntentToCommit: purchase) ?? .default
        
        return intent
    }
}
