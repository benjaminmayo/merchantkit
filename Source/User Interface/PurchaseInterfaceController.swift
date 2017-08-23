public protocol PurchaseInterfaceControllerDelegate : class {
    func purchaseInterfaceControllerDidChangeFetchingState(_ controller: PurchaseInterfaceController)
    
    func purchaseInterfaceController(_ controller: PurchaseInterfaceController, didChangeStatesFor products: Set<Product>)
    func purchaseInterfaceController(_ controller: PurchaseInterfaceController, didCommit purchase: Purchase, with result: PurchaseInterfaceController.CommitPurchaseResult)
    func purchaseInterfaceController(_ controller: PurchaseInterfaceController, didRestorePurchasesWith result: PurchaseInterfaceController.RestorePurchasesResult)
}

/// This controller manages the purchased state of the supplied `products`. This controller is a convenience wrapper around several `Merchant` tasks and is intended to be used to display a user interface, like a storefront.
///
/// Create a controller and call `fetchDataIfNecessary()` when the user interface is presented. Update UI in response to state changes, via the `delegate`.
///
/// If the user decides to purchase a displayed product, use the `commit(_:)` method to begin a purchase flow. Alternatively, call `restorePurchases()` if the user wants to restore an earlier transaction.
public final class PurchaseInterfaceController {
    public let products: Set<Product>

    public weak var delegate: PurchaseInterfaceControllerDelegate?
    
    public var isFetching: Bool {
        return self.availablePurchasesTask != nil
    }
    
    public var fetchError: FetchError? {
        return self.availablePurchases?.error
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
    
    private var availablePurchases: FetchResult?
    
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
        guard self.availablePurchases == nil else { return }
        
        self.fetchPurchases(onFetchingStateChanged: self.didChangeFetchingState, onCompletion: { result in
            self.availablePurchases = result
            
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
                            error = .genericProblem
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
    public enum ProductState {
        case unknown
        case purchased
        case purchasable(Purchase)
        case purchasing(Purchase)
        case purchaseUnavailable
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
            case genericProblem
        }
    }
    
    public enum RestorePurchasesResult {
        case succeeded(Set<Product>)
        case failed(Error)
    }
    
    public enum FetchError : Swift.Error {
        case networkError(URLError)
        case genericProblem
    }
}

extension PurchaseInterfaceController.ProductState : Equatable {
    public static func ==(lhs: PurchaseInterfaceController.ProductState, rhs: PurchaseInterfaceController.ProductState) -> Bool {
        switch (lhs, rhs) {
            case (.unknown, .unknown): return true
            case (.purchased, .purchased): return true
            case (.purchasable(let a), .purchasable(let b)): return a == b
            case (.purchasing(let a), .purchasing(let b)): return a == b
            case (.purchaseUnavailable, .purchaseUnavailable): return true
            default: return false
        }
    }
}

extension PurchaseInterfaceController {
    private enum FetchResult {
        case succeeded(PurchaseSet)
        case failed(FetchError)
        
        public var error: FetchError? {
            switch self {
                case .failed(let error): return error
                default: return nil
            }
        }
    }
    
    private func fetchPurchases(onFetchingStateChanged fetchingStateChanged: @escaping () -> Void, onCompletion completion: @escaping (FetchResult) -> Void) {
        let task = self.merchant.availablePurchasesTask(for: self.products)
        task.onCompletion = { result in
            self.availablePurchasesTask = nil
            fetchingStateChanged()
            
            let loadResult: FetchResult
            
            switch result {
                case .failed(let error):
                    let resultError: FetchError
                    let underlyingError = (error as NSError).userInfo[NSUnderlyingErrorKey] as? Error
                    
                    switch (error, underlyingError) {
                    case (let networkError as URLError, _), (_, let networkError as URLError):
                        resultError = .networkError(networkError)
                    default:
                        resultError = .genericProblem
                    }
                    
                    loadResult = .failed(resultError)
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
            
            switch (self.availablePurchases, result) {
            case (.failed(_)?, .succeeded(_)):
                self.availablePurchases = result
                didChange = true
            case (.succeeded(_)?, .succeeded(_)):
                self.availablePurchases = result
                didChange = true
            case (nil, _):
                self.availablePurchases = result
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
            state = .purchased
        } else if let commitPurchaseTask = self.commitPurchaseTask, commitPurchaseTask.purchase.productIdentifier == product.identifier {
            state = .purchasing(commitPurchaseTask.purchase)
        } else if let purchaseResult = self.availablePurchases {
            switch purchaseResult {
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
        guard case .networkError(_)? = self.fetchError else { return }
        
        self.fetchPurchases(onFetchingStateChanged: {}, onCompletion: { result in
            self.availablePurchases = result
            
            self.didChangeState(for: self.products)
        })
    }
}
