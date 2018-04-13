public protocol PurchaseInterfaceControllerDelegate : class {
    func purchaseInterfaceControllerDidChangeFetchingState(_ controller: PurchaseInterfaceController)
    
    func purchaseInterfaceController(_ controller: PurchaseInterfaceController, didChangeStatesFor products: Set<Product>)
    func purchaseInterfaceController(_ controller: PurchaseInterfaceController, didCommit purchase: Purchase, with result: PurchaseInterfaceController.CommitPurchaseResult)
    func purchaseInterfaceController(_ controller: PurchaseInterfaceController, didRestorePurchasesWith result: PurchaseInterfaceController.RestorePurchasesResult)
}

/// This controller is actively being worked on and the API surface is considered volatile.

/// This controller manages the purchased state of the supplied `products`. This controller is a convenience wrapper around several `Merchant` tasks and is intended to be used to display a user interface, like a storefront.
///
/// Create a controller and call `fetchDataIfNecessary()` when the user interface is presented. Update UI in response to state changes, via the `delegate`.
///
/// If the user decides to purchase a displayed product, use the `commit(_:)` method to begin a purchase flow. Alternatively, call `restorePurchases()` if the user wants to restore an earlier transaction.

public final class PurchaseInterfaceController {
    public let products: Set<Product>

    public weak var delegate: PurchaseInterfaceControllerDelegate?
    
    public var fetchingState: FetchingState {
        if self.availablePurchasesTask != nil {
            return .loading
        }
        
        switch self.availablePurchasesFetchResult {
            case .failed(let reason)?:
                return .failed(reason)
            default:
                return .dormant
        }
    }
    
    public var automaticallyRefetchIfNetworkAvailabilityChanges: Bool = false {
        didSet {
            if oldValue != self.automaticallyRefetchIfNetworkAvailabilityChanges {
                self.updateNetworkAvailabilityCenterState()
            }
        }
    }
    
    private let merchant: Merchant
    
    private var availablePurchasesTask: AvailablePurchasesTask?
    private var commitPurchaseTask: CommitPurchaseTask?
    private var restorePurchasesTask: RestorePurchasesTask?
    
    private var availablePurchasesFetchResult: FetchResult<PurchaseSet>?
    
    private var stateForProductIdentifier = [String : ProductState]()
    
    private let networkAvailabilityCenter = NetworkAvailabilityCenter()
    
    public init(displaying products: Set<Product>, with merchant: Merchant) {
        self.products = products
        self.merchant = merchant
        
        for product in products {
            self.stateForProductIdentifier[product.identifier] = self.determineState(for: product)
        }
        
        self.networkAvailabilityCenter.onConnectivityChanged = { [weak self] in
            self?.didChangeNetworkConnectivity()
        }
    }
    
    public func state(for product: Product) -> ProductState {
        return self.stateForProductIdentifier[product.identifier] ?? .unknown
    }
    
    public func fetchDataIfNecessary() {
        guard self.availablePurchasesFetchResult == nil else { return }
        
        self.fetchPurchases(onFetchingStateChanged: self.didChangeFetchingState, onCompletion: { result in
            self.availablePurchasesFetchResult = result
            
            self.didChangeState(for: self.products)
        })
    }
    
    /// Purchase a `Product` managed by this controller.
    public func commit(_ purchase: Purchase) {
        guard let product = self.products.first(where: { product in
            product.identifier == purchase.productIdentifier
        }) else { fatalError("committing incompatible purchase") }
        
        let task = self.merchant.commitPurchaseTask(for: purchase)
        task.onCompletion = { result in
            self.commitPurchaseTask = nil
            
            self.didChangeState(for: [product])
            
            switch result {
                case .succeeded(_):
                    DispatchQueue.main.async {
                        self.delegate?.purchaseInterfaceController(self, didCommit: purchase, with: .succeeded)
                    }
                case .failed(let baseError):
                    let error: CommitPurchaseResult.Error
                    let shouldDisplayError: Bool
                    
                    let underlyingError = (baseError as NSError).userInfo[NSUnderlyingErrorKey] as? Error
                    
                    switch (baseError, underlyingError) {
                        case (SKError.paymentCancelled, _):
                            error = .userCancelled
                            shouldDisplayError = false
                        case (SKError.storeProductNotAvailable, _):
                            error = .purchaseNotAvailable
                            shouldDisplayError = true
                        case (SKError.paymentInvalid, _):
                            error = .paymentInvalid
                            shouldDisplayError = true
                        case (SKError.paymentNotAllowed, _):
                            error = .paymentNotAllowed
                            shouldDisplayError = true
                        case (let networkError as URLError, _), (_, let networkError as URLError):
                            error = .networkError(networkError)
                            shouldDisplayError = true
                        default:
                            error = .genericProblem(baseError)
                            shouldDisplayError = true
                }
                
                DispatchQueue.main.async {
                    self.delegate?.purchaseInterfaceController(self, didCommit: purchase, with: .failed(error, shouldDisplayError: shouldDisplayError))
                }
            }
        }
        
        task.start()
        
        self.commitPurchaseTask = task
        self.didChangeState(for: [product])
    }
    
    public func restorePurchases() {
        let task = self.merchant.restorePurchasesTask()
        task.onCompletion = { result in
            self.restorePurchasesTask = nil
            
            let restoreResult: RestorePurchasesResult
            
            switch result {
                case .succeeded(let restoredProducts):
                    let updatedProducts = self.products.intersection(restoredProducts)
                    self.didChangeState(for: updatedProducts)
                
                    restoreResult = .succeeded(updatedProducts)
                case .failed(let error):
                    restoreResult = .failed(error)
            }
            
            DispatchQueue.main.async {
                self.delegate?.purchaseInterfaceController(self, didRestorePurchasesWith: restoreResult)
            }
        }
            
        task.start()
        self.restorePurchasesTask = task
    }
}

extension PurchaseInterfaceController {
    public enum ProductState : Equatable {
        case unknown // consider loading/failure cases of fetchingState
        case purchased(PurchaseInfo?) // product is owned, `PurchaseInfo` represents the current price (etc) for the represented product - this info may not be available
        case purchasable(Purchase) // product can be purchased, refer to `Purchase`
        case purchasing(Purchase) // product is currently being purchased, probably show a loading UI for that particular product
        case purchaseUnavailable // purchase cannot be made, show some kind of warning in the UI
        
        public struct PurchaseInfo : Equatable {
            public let price: Price
            @available(iOS 11.2, *)
            public var subscriptionTerms: SubscriptionTerms? { return self._subscriptionTerms }
            
            private let _subscriptionTerms: SubscriptionTerms?
            
            internal init(price: Price, subscriptionTerms: SubscriptionTerms?) {
                self.price = price
                self._subscriptionTerms = subscriptionTerms
            }
        }
    }
    
    public enum FetchingState {
        case dormant
        case loading
        case failed(FailureReason)
        
        public enum FailureReason {
            case networkFailure(URLError)
            case storeKitFailure(SKError)
            case genericProblem
        }
    }
    
    public enum CommitPurchaseResult {
        case succeeded
        case failed(Error, shouldDisplayError: Bool)
        
        public enum Error : Swift.Error {
            case userCancelled
            case networkError(URLError)
            case purchaseNotAvailable
            case paymentNotAllowed
            case paymentInvalid
            case genericProblem(Swift.Error)
        }
    }
    
    public enum RestorePurchasesResult {
        case succeeded(Set<Product>)
        case failed(Error)
    }
}

extension PurchaseInterfaceController {
    private enum FetchResult<T> {
        case succeeded(T)
        case failed(FetchingState.FailureReason)
    }
    
    private func fetchPurchases(onFetchingStateChanged fetchingStateChanged: @escaping () -> Void, onCompletion completion: @escaping (FetchResult<PurchaseSet>) -> Void) {
        let task = self.merchant.availablePurchasesTask(for: self.products)
        task.ignoresPurchasedProducts = false
        task.onCompletion = { result in
            self.availablePurchasesTask = nil
            fetchingStateChanged()
            
            let loadResult: FetchResult<PurchaseSet>
            
            switch result {
                case .failed(let error):
                    let failureReason: FetchingState.FailureReason
                    let underlyingError = (error as NSError).userInfo[NSUnderlyingErrorKey] as? Error
                    
                    switch (error, underlyingError) {
                        case (let networkError as URLError, _), (_, let networkError as URLError):
                            failureReason = .networkFailure(networkError)
                        case (let error as SKError, _):
                            failureReason = .storeKitFailure(error)
                        default:
                            failureReason = .genericProblem
                    }
                    
                    loadResult = .failed(failureReason)
                case .succeeded(let purchases):
                    loadResult = .succeeded(purchases)
            }
            
            completion(loadResult)
        }
        
        task.start()
        
        self.availablePurchasesTask = task
        fetchingStateChanged()
    }
    
    private func refetchAvailablePurchases() {
        self.fetchPurchases(onFetchingStateChanged: {}, onCompletion: { result in
            let didChange: Bool
            
            switch (self.availablePurchasesFetchResult, result) {
                case (.failed(_)?, .succeeded(_)):
                    self.availablePurchasesFetchResult = result
                    didChange = true
                case (.succeeded(_)?, .succeeded(_)):
                    self.availablePurchasesFetchResult = result
                    didChange = true
                case (nil, _):
                    self.availablePurchasesFetchResult = result
                    didChange = true
                case (_, .failed(_)):
                    didChange = false
            }
            
            if didChange {
                self.didChangeState(for: self.products)
            }
        })
    }
    
    private func determineState(for product: Product) -> ProductState {
        let state: ProductState
        
        if self.merchant.state(for: product).isPurchased {
            let purchaseInfo: ProductState.PurchaseInfo? = {
                switch self.availablePurchasesFetchResult {
                    case .succeeded(let purchases)?:
                        if let purchase = purchases.purchase(for: product) {
                            let subscriptionTerms: SubscriptionTerms?
                            
                            if #available(iOS 11.2, *) {
                                subscriptionTerms = purchase.subscriptionTerms
                            } else {
                                subscriptionTerms = nil
                            }
                            
                            return ProductState.PurchaseInfo(price: purchase.price, subscriptionTerms: subscriptionTerms)
                        }
                    default:
                        break
                }
                
                return nil
            }()
            
            state = .purchased(purchaseInfo)
        } else if let commitPurchaseTask = self.commitPurchaseTask, commitPurchaseTask.purchase.productIdentifier == product.identifier {
            state = .purchasing(commitPurchaseTask.purchase)
        } else if let availablePurchasesResult = self.availablePurchasesFetchResult {
            switch availablePurchasesResult {
                case .succeeded(let purchases):
                    if let purchase = purchases.purchase(for: product) {
                        state = .purchasable(purchase)
                    } else {
                        state = .purchaseUnavailable
                    }
                case .failed(_):
                    state = .unknown
            }
        } else {
            state = .unknown
        }
        
        return state
    }
    
    private func didChangeFetchingState() {
        DispatchQueue.main.async {
            self.delegate?.purchaseInterfaceControllerDidChangeFetchingState(self)
        }
    }
    
    private func didChangeState(for products: Set<Product>) {
        var changedProducts = Set<Product>()
        
        for product in products {
            let currentState = self.state(for: product)
            let newState = self.determineState(for: product)
            
            if currentState != newState {
                self.stateForProductIdentifier[product.identifier] = newState
                
                changedProducts.insert(product)
            }
        }
        
        DispatchQueue.main.async {
            self.delegate?.purchaseInterfaceController(self, didChangeStatesFor: changedProducts)
        }
    }
    
    private func updateNetworkAvailabilityCenterState() {
        if self.automaticallyRefetchIfNetworkAvailabilityChanges {
            self.networkAvailabilityCenter.observeChanges()
        } else {
            self.networkAvailabilityCenter.stopObservingChanges()
        }
    }
    
    private func didChangeNetworkConnectivity() {
        guard self.networkAvailabilityCenter.isConnectedToNetwork else { return }
        
        if case .failed(.networkFailure(_))? = self.availablePurchasesFetchResult {
            return
        }
        
        self.fetchPurchases(onFetchingStateChanged: {}, onCompletion: { result in
            self.availablePurchasesFetchResult = result
            
            self.didChangeState(for: self.products)
        })
    }
}
