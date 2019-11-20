import Foundation
import StoreKit

/// The `Merchant` manages a set of registered products. The `Merchant` creates tasks to perform various operations, and tracks the `PurchasedState` of products.
/// There will typically be only one `Merchant` instantiated in an application.
public final class Merchant {
    /// The `delegate` will be called to respond to various events.
    public let delegate: MerchantDelegate
    
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
    internal let storeInterface: StoreInterface
    internal private(set) var latestFetchedReceipt: Receipt?
    internal let storePurchaseObservers = StorePurchaseObservers()

    private let configuration: Configuration

    private var registeredProducts: [String : Product] = [:]
    private var activeTasks: [MerchantTask] = []
    
    private var hasSetup: Bool = false
    
    private var receiptFetchers: [ReceiptFetchPolicy : ReceiptDataFetcher] = [:]
    
    private var pendingProducts = PendingProductSet()
    
    private let nowDate: Date = Date()

    /// Create a `Merchant` as part of application launch lifecycle. Use `Merchant.Configuration.default` for an appropriate default setup, or you can supply your own customized `Merchant.Configuration`.
    /// The `delegate` enables the application to be centrally alerted to changes in state. Depending on the functionality of your app, you may not need to do any actual work in the delegate methods. Remember, you can always ask for the current purchased state of a `Product` using `Merchant.state(for:)`.
    /// The `consumableHandler` is **required** if your application uses consumable products.
    public init(configuration: Configuration, delegate: MerchantDelegate, consumableHandler: MerchantConsumableProductHandler? = nil) {
        self.configuration = configuration
        self.delegate = delegate
        self.consumableHandler = consumableHandler
        
        self.storeInterface = StoreKitStoreInterface(paymentQueue: .default())
    }
    
    /// Register products that you want to use in your application. Products must be registered before their states are consistently valid. Products should be registered as early as possible, typically just before calling `setup()`.
    public func register<Products : Sequence>(_ products: Products) where Products.Iterator.Element == Product {
        for product in products {
            self.registeredProducts[product.identifier] = product
        }
    }
    
    /// Call this method at application launch. It performs necessary initialization routines.
    public func setup() {
        guard !self.hasSetup else { return }
        self.hasSetup = true
        
        self.storeInterface.setup(withDelegate: self)
        
        self.checkReceipt(updateProducts: .all, policy: .onlyFetch, reason: .initialization, completion: { result in
            switch result {
                case .failure(TestingReceiptValidator.Error.failingInitializationOnPurposeForTesting):
                    self.logger.log(message: "`Merchant` is using a testing configuration that intentionally fails to validate receipts upon initialization. This is useful for testing but should not be deployed to production.", category: .initialization)
                case .success(_), .failure(_):
                    break
            }
        })
        
        self.logger.log(message: "`Merchant` has been setup, with \(self.registeredProducts.count) registered \(self.registeredProducts.count == 1 ? "product" : "products").", category: .initialization)
        
        if self.registeredProducts.isEmpty {
            self.logger.log(message: "There are no registered products for the `Merchant`. Remember to call `Merchant.register(_)` to register a sequence of `Product` items.", category: .initialization)
        }
    }
    
    /// Returns a registered product for a given `productIdentifier`, or `nil` if not found.
    public func product(withIdentifier productIdentifier: String) -> Product? {
        return self.registeredProducts[productIdentifier]
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
            let products = products.isEmpty ? Set(self.registeredProducts.values) : products
            
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
    
    /// Internal initializer to enable hooks for testing. The public initializer always uses the `StoreKitStoreInterface`.
    internal init(configuration: Configuration, delegate: MerchantDelegate, consumableHandler: MerchantConsumableProductHandler?, storeInterface: StoreInterface) {
        self.configuration = configuration
        self.delegate = delegate
        self.consumableHandler = consumableHandler
        
        self.storeInterface = storeInterface
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
        guard let index = self.activeTasks.firstIndex(where: { $0 === task }) else { return }
        
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
            
            self.delegate.merchantDidChangeLoadingState(self)
        }
    }
}

// MARK: Receipt fetch and validation
extension Merchant {
    internal typealias CheckReceiptCompletion = (Result<Set<Product>, Error>) -> Void
    
    private func checkReceipt(updateProducts updateType: ReceiptUpdateType, policy: ReceiptFetchPolicy, reason: ReceiptValidationRequest.Reason, completion: @escaping CheckReceiptCompletion = { _ in }) {
        let fetcher: ReceiptDataFetcher
        let isStarted: Bool
        
        if let activeFetcher = self.receiptFetchers[policy] { // the same fetcher may be pooled and used multiple times, this is because `enqueueCompletion` can add blocks even after the fetcher has been started
            fetcher = activeFetcher
            isStarted = true
            
            self.logger.log(message: "Reused receipt fetcher for \(policy)", category: .receipt)
        } else {
            fetcher = self.storeInterface.makeReceiptFetcher(for: policy)
            isStarted = false
            
            self.receiptFetchers[policy] = fetcher
            self.logger.log(message: "Created receipt fetcher for \(policy)", category: .receipt)
        }
        
        fetcher.enqueueCompletion { [weak self] dataResult in
            guard let self = self else { return }
            
            switch dataResult {
                case .success(let receiptData):
                    self.logger.log(message: "Receipt fetch succeeded: found \(receiptData.count) bytes", category: .receipt)
                    
                    self.validateReceipt(with: receiptData, reason: reason, completion: { [weak self] validateResult in
                        guard let self = self else { return }
                        
                        switch validateResult {
                            case .success(let receipt):
                                self.logger.log(message: "Receipt validation succeeded: \(receipt)", category: .receipt)
                                
                                self.latestFetchedReceipt = receipt
                                
                                let updatedProducts = self.updateStorageWithValidatedReceipt(receipt, updateProducts: updateType)
                            
                                if !updatedProducts.isEmpty {
                                    DispatchQueue.main.async {
                                        self.didChangeState(for: updatedProducts)
                                    }
                                }
                                
                                completion(.success(updatedProducts))
                            case .failure(let error):
                                self.logger.log(message: "Receipt validation failed: \(error)", category: .receipt)

                                completion(.failure(error))
                        }
                    })
                case .failure(let error):
                    self.logger.log(message: "Receipt fetch failed: \(error)", category: .receipt)

                    completion(.failure(error))
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
    
    private func validateReceipt(with data: Data, reason: ReceiptValidationRequest.Reason, completion: @escaping (Result<Receipt, Error>) -> Void) {
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
            
            let result: PurchaseStorageUpdateResult
            
            let expiryDate = entries.compactMap { $0.expiryDate }.max()
            
            func logMessage(for result: PurchaseStorageUpdateResult) -> String {
                switch result {
                    case .didChangeRecords:
                        return "Purchase storage did change."
                    case .noChanges:
                        return "Purchase storage unchanged."
                }
            }
                
            if let expiryDate = expiryDate, !self.isSubscriptionActive(forExpiryDate: expiryDate) {
                result = self.configuration.storage.removeRecord(forProductIdentifier: productIdentifier)
                
                self.logger.log(message: "Removed record for \(productIdentifier), given expiry date \(expiryDate). " + logMessage(for: result), category: .purchaseStorage)
            } else {
                let record = PurchaseRecord(productIdentifier: productIdentifier, expiryDate: expiryDate)
            
                result = self.configuration.storage.save(record)
                
                self.logger.log(message: "Saved record: \(record). " + logMessage(for: result), category: .purchaseStorage)
            }
            
            if result == .didChangeRecords {
                updatedProducts.insert(product)
            }
        }
        
        if updateType == .all { // clean out from storage if registered products are not in the receipt
            let registeredProductIdentifiers = Set(self.registeredProducts.map { $0.key })
            let identifiersForProductsNotInReceipt = registeredProductIdentifiers.subtracting(receipt.productIdentifiers)
            
            for productIdentifier in identifiersForProductsNotInReceipt {
                let result = self.configuration.storage.removeRecord(forProductIdentifier: productIdentifier)
                self.logger.log(message: "Removed record for \(productIdentifier): product not in receipt", category: .purchaseStorage)

                if result == .didChangeRecords {
                    updatedProducts.insert(self.registeredProducts[productIdentifier]!)
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

// MARK: Utilities
extension Merchant {
    /// Check if a subscription should be considered active for a given expiry date.
    private func isSubscriptionActive(forExpiryDate expiryDate: Date) -> Bool {
        let leewayTimeInterval = self.configuration.receiptValidator.subscriptionRenewalLeeway.allowedElapsedDuration
        
        return expiryDate.addingTimeInterval(leewayTimeInterval) > self.nowDate
    }
    
    /// Warns users if `Merchant` has not been correctly configured.
    private func ensureSetup() {
        guard !self.hasSetup else { return }
        
        // Print the warning to the console. As this is a serious usage error, we do not route it through the optional framework logging.
        print("Merchant is attempting to vend purchases, but the `Merchant` has not been setup. Remember to call `Merchant.setup()` during application launch.")
    }
}

// MARK: `StoreInterfaceDelegate` Conformance
extension Merchant : StoreInterfaceDelegate {
    internal func storeInterfaceWillUpdatePurchases(_ storeInterface: StoreInterface) {
        
    }
    
    internal func storeInterfaceDidUpdatePurchases(_ storeInterface: StoreInterface) {
        if let pendingPurchased = self.pendingProducts[.purchased].nonEmpty {
            self.logger.log(message: "Invoked receipt update for purchases \(pendingPurchased)", category: .receipt)
            
            self.checkReceipt(updateProducts: .specific(productIdentifiers: Set(pendingPurchased.map { $0.identifier })), policy: .onlyFetch, reason: .completePurchase)
        }
        
        self.pendingProducts[.purchased].removeAll()
    }
    
    internal func storeInterface(_ storeInterface: StoreInterface, didPurchaseProductWith productIdentifier: String, completion: @escaping () -> Void) {
        func didCompletePurchase() {
            completion()
        }
        
        if let product = self.product(withIdentifier: productIdentifier) {
            if product.kind == .consumable { // consumable product purchases are not recorded
                guard let consumableHandler = self.consumableHandler else {
                    MerchantKitFatalError.raise("`Merchant` tried to purchase a consumable product but the `Merchant.consumableHandler` was not set. You must provide a `consumbleHandler` when you instantiate the `Merchant` to handle consumables.")
                }
                
                consumableHandler.merchant(self, consume: product, completion: didCompletePurchase)
            } else { // non-consumable and subscription products are recorded
                let knownExpiryDate = self.configuration.storage.record(forProductIdentifier: product.identifier)?.expiryDate
                
                let record = PurchaseRecord(productIdentifier: product.identifier, expiryDate: knownExpiryDate)
                let result = self.configuration.storage.save(record)
            
                if result == .didChangeRecords {
                    self.didChangeState(for: [product])
                }
                
                if case .subscription(_) = product.kind {
                    self.pendingProducts[.purchased].insert(product) // we need to get the receipt to find the new expiry date, the `PurchaseRecord` will be updated when that information is available
                }
                
                didCompletePurchase()
            }
            
            for observer in self.storePurchaseObservers.observers(for: \.purchaseProducts) {
                observer.merchant(self, didFinishPurchaseWith: .success, forProductWith: product.identifier)
            }
        } else {
            self.logger.log(message: "Purchase was not handled as the `productIdentifier` (\"\(productIdentifier)\") was unknown to the `Merchant`. If you recognize the product identifier, ensure the corresponding `Product` has been registered before attempting to commit purchases.", category: .storeInterface)
        }
    }
    
    internal func storeInterface(_ storeInterface: StoreInterface, didRestorePurchaseForProductWith productIdentifier: String) {
        if let product = self.product(withIdentifier: productIdentifier) {
            if case .subscription(_) = product.kind {
                self.pendingProducts[.restored].insert(product)
            } else {
                let record = PurchaseRecord(productIdentifier: product.identifier, expiryDate: nil)

                let result = self.configuration.storage.save(record)
                
                if result == .didChangeRecords {
                    self.didChangeState(for: [product])
                }
                
                for observer in self.storePurchaseObservers.observers(for: \.restorePurchasedProducts) {
                    observer.merchant(self, didRestorePurchasedProductWith: product.identifier)
                }
            }
        } else {
            self.logger.log(message: "Restored purchase was not handled as the `productIdentifier` (\"\(productIdentifier)\") was unknown to the `Merchant`. If you recognize the product identifier, ensure the corresponding `Product` has been registered before attempting to restore purchases.", category: .storeInterface)
        }
    }
    
    internal func storeInterface(_ storeInterface: StoreInterface, didFailToPurchaseProductWith productIdentifier: String, error: Error) {
        if let product = self.product(withIdentifier: productIdentifier) {
            for observer in self.storePurchaseObservers.observers(for: \.purchaseProducts) {
                observer.merchant(self, didFinishPurchaseWith: .failure(error), forProductWith: product.identifier)
            }
        } else {
            self.logger.log(message: "Purchase failure \"\(error.localizedDescription)\" was not handled as the `productIdentifier` (\"\(productIdentifier)\") was unknown to the `Merchant`. If you recognize the product identifier, ensure the corresponding `Product` has been registered before attempting to commit purchases.", category: .storeInterface)
        }
    }
    
    internal func storeInterfaceWillStartRestoringPurchases(_ storeInterface: StoreInterface) {
        for observer in self.storePurchaseObservers.observers(for: \.restorePurchasedProducts) {
            observer.merchantDidStartRestoringProducts(self)
        }
    }
    
    internal func storeInterface(_ storeInterface: StoreInterface, didFinishRestoringPurchasesWith result: Result<Void, Error>) {
        if let pendingRestored = self.pendingProducts[.restored].nonEmpty {
            self.checkReceipt(updateProducts: .specific(productIdentifiers: Set(pendingRestored.map { $0.identifier })), policy: .onlyFetch, reason: .restorePurchases, completion: { updatedProductsResult in
                let restoredProducts = (try? updatedProductsResult.get().filter { self.state(for: $0).isPurchased }) ?? []
                 
                for observer in self.storePurchaseObservers.observers(for: \.restorePurchasedProducts) {
                    for product in restoredProducts {
                        observer.merchant(self, didRestorePurchasedProductWith: product.identifier)
                    }
                }
                
                for observer in self.storePurchaseObservers.observers(for: \.restorePurchasedProducts) {
                    observer.merchant(self, didFinishRestoringProductsWith: result)
                }
            })
            
            self.logger.log(message: "Invoked receipt update for restored purchases \(pendingRestored)", category: .receipt)
        } else {
            for observer in self.storePurchaseObservers.observers(for: \.restorePurchasedProducts) {
                observer.merchant(self, didFinishRestoringProductsWith: result)
            }
        }
        
        self.pendingProducts[.restored].removeAll()
    }
    
    internal func storeInterface(_ storeInterface: StoreInterface, responseForStoreIntentToCommitPurchaseFrom source: Purchase.Source) -> StoreIntentResponse {
        guard let product = self.product(withIdentifier: source.skProduct.productIdentifier) else { return .defer }
        
        let purchase = Purchase(from: source, for: product)
        let intent = self.delegate.merchant(self, didReceiveStoreIntentToCommit: purchase)
        
        return intent
    }
}
