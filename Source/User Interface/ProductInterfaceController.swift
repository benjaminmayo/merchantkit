import Foundation 
import StoreKit

public protocol ProductInterfaceControllerDelegate : AnyObject {
    func productInterfaceControllerDidChangeFetchingState(_ controller: ProductInterfaceController)
    
    func productInterfaceController(_ controller: ProductInterfaceController, didChangeStatesFor products: Set<Product>)
    func productInterfaceController(_ controller: ProductInterfaceController, didCommit purchase: Purchase, with result: ProductInterfaceController.CommitPurchaseResult)
    func productInterfaceController(_ controller: ProductInterfaceController, didRestorePurchasesWith result: ProductInterfaceController.RestorePurchasesResult)
}

/// This controller is actively being worked on and the API surface is considered volatile.
/// This controller manages the purchased state of the supplied `products`. This controller is a convenience wrapper around several `Merchant` tasks and is intended to be used to display a user interface, like a storefront.
///
/// Create a controller and call `fetchDataIfNecessary()` when the user interface is presented. Update UI in response to state changes, via the `delegate`. Delegate methods are invoked on the main queue.
///
/// If the user decides to purchase a displayed product, use the `commit(_:)` method to begin a purchase flow. Alternatively, call `restorePurchases()` if the user wants to restore an earlier transaction.

public final class ProductInterfaceController {
    public let products: Set<Product>

    public weak var delegate: ProductInterfaceControllerDelegate?
    
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
    
    private var availablePurchasesFetchResult: FetchResult?
    
    private var stateForProductIdentifier = [String : ProductState]()
    
    private let networkAvailabilityCenter = NetworkAvailabilityCenter()
    
    public init(products: Set<Product>, with merchant: Merchant) {
        self.products = products
        self.merchant = merchant
        
        for product in products {
            self.stateForProductIdentifier[product.identifier] = self._determineCurrentState(for: product)
        }
        
        self.networkAvailabilityCenter.onConnectivityChanged = { [weak self] in
            self?.didChangeNetworkConnectivity()
        }
    }
    
    public func state(for product: Product) -> ProductState {
        return self.stateForProductIdentifier[product.identifier] ?? .unknown
    }
    
    public func fetchDataIfNecessary() {
        switch self.availablePurchasesFetchResult {
            case .succeeded(_)?: return
            case .failed(_)?:
                self.refetchAvailablePurchases(silentlyFetch: false)
                return
            default:
                break
        }
                
        self.fetchPurchases(onFetchingStateChanged: { [weak self] in
            guard let self = self else { return }
            
            self.delegate?.productInterfaceControllerDidChangeFetchingState(self)
        }, onCompletion: { [weak self] result in
            guard let self = self else { return }
            
            self.availablePurchasesFetchResult = result
            
            self.didChangeState(for: self.products)
        })
    }
    
    /// Purchase a `Product` managed by this controller.
    public func commit(_ purchase: Purchase, applying discount: PurchaseDiscount? = nil) {
        guard let product = self.products.first(where: { product in
            product.identifier == purchase.productIdentifier
        }) else { MerchantKitFatalError.raise("The `Purchase` cannot be committed to this `ProductInterfaceController` instance as it is not vended by it. This indicates a logic error in your application.") }
        
        let task = self.merchant.commitPurchaseTask(for: purchase, applying: discount)
        task.onCompletion = { result in
            self.commitPurchaseTask = nil
            
            DispatchQueue.main.async {
                self.didChangeState(for: [product])
                
                switch result {
                    case .success(_):
                        self.delegate?.productInterfaceController(self, didCommit: purchase, with: .success)
                    case .failure(let baseError):
                        let error: CommitPurchaseError
                        
                        let underlyingError = (baseError as NSError).userInfo[NSUnderlyingErrorKey] as? Error
                        
                        switch (baseError, underlyingError) {
                            case (SKError.paymentCancelled, _):
                                error = .userCancelled
                            #if os(iOS)
                            case (SKError.storeProductNotAvailable, _):
                                error = .purchaseNotAvailable
                            #endif
                            case (SKError.paymentInvalid, _):
                                error = .paymentInvalid
                            case (SKError.paymentNotAllowed, _):
                                error = .paymentNotAllowed
                            case (let networkError as URLError, _), (_, let networkError as URLError):
                                error = .networkError(networkError)
                            default:
                                error = .genericProblem(baseError)
                        }

                        self.delegate?.productInterfaceController(self, didCommit: purchase, with: .failure(error))
                }
            }
        }
        
        task.start()
        
        self.commitPurchaseTask = task
        self.didChangeState(for: [product])
    }
    
    public func restorePurchases() {
        guard self.restorePurchasesTask == nil else { return }
        
        let task = self.merchant.restorePurchasesTask()
        task.onCompletion = { [weak self] result in
            guard let self = self else { return }
            
            self.restorePurchasesTask = nil
            
            DispatchQueue.main.async {
                let restoreResult: RestorePurchasesResult = result.map { restoredProducts in
                    self.products.intersection(restoredProducts)
                }
                
                if let updatedProducts = try? restoreResult.get() {
                    self.didChangeState(for: updatedProducts)
                }
                
                self.delegate?.productInterfaceController(self, didRestorePurchasesWith: restoreResult)
            }
        }
            
        task.start()
        self.restorePurchasesTask = task
    }
}

extension ProductInterfaceController {
    public enum ProductState : Equatable {
        case unknown // consider loading/failure cases of fetchingState
        case purchased(PurchasedProductInfo, PurchaseMetadata?) // product is owned, `PurchaseMetadata` represents the current price and other information about the purchase, if it was available to buy. This metadata may not always be available.
        case purchasable(Purchase) // product can be purchased, refer to `Purchase`
        case purchasing(Purchase) // product is currently being purchased, probably show a loading UI for that particular product
        case purchaseUnavailable // purchase cannot be made, show some kind of warning in the UI
        
        public struct PurchaseMetadata : Equatable {
            public let price: Price
            private let _subscriptionTerms: SubscriptionTerms? // hidden to support <iOS11.2 versions
            
            internal init(price: Price, subscriptionTerms: SubscriptionTerms?) {
                self.price = price
                self._subscriptionTerms = subscriptionTerms
            }
            
            @available(iOS 11.2, macOS 10.13.2, *)
            public var subscriptionTerms: SubscriptionTerms? {
                return self._subscriptionTerms
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
            case genericProblem(Error)
			case userNotAllowedToMakePurchases
        }
    }
    
    public typealias CommitPurchaseResult = Result<Void, CommitPurchaseError>
    
    public enum CommitPurchaseError : Error {
        case userCancelled
        case networkError(URLError)
        case purchaseNotAvailable
        case paymentNotAllowed
        case paymentInvalid
        case genericProblem(Swift.Error)
        
        public var shouldDisplayInUserInterface: Bool {
            switch self {
                case .userCancelled: return false
                default: return true
            }
        }
    }
    
    public typealias RestorePurchasesResult = Result<Set<Product>, Error>
}

extension ProductInterfaceController {
    private enum FetchResult {
        case succeeded(PurchaseSet)
        case failed(FetchingState.FailureReason)
    }
    
    private func fetchPurchases(onFetchingStateChanged fetchingStateChanged: @escaping () -> Void, onCompletion completion: @escaping (FetchResult) -> Void) {
        let task = self.merchant.availablePurchasesTask(for: self.products)
        task.onCompletion = { [weak self] result in
            guard let self = self else { return }
            
            self.availablePurchasesTask = nil
            
            let loadResult: FetchResult
            
            switch result {
                case .failure(let error):
                    let failureReason: FetchingState.FailureReason
                    let underlyingError = (error as NSError).userInfo[NSUnderlyingErrorKey] as? Error
                    
                    switch (error, underlyingError) {
						case (AvailablePurchasesFetcherError.userNotAllowedToMakePurchases, _):
							failureReason = .userNotAllowedToMakePurchases
                        case (let networkError as URLError, _), (_, let networkError as URLError):
                            failureReason = .networkFailure(networkError)
                        case (let skError as SKError, _):
                            failureReason = .storeKitFailure(skError)
						case (_, let skError as SKError):
							failureReason = .storeKitFailure(skError)
						case (AvailablePurchasesFetcherError.other(let error), _):
							failureReason = .genericProblem(error)
                        default:
                            failureReason = .genericProblem(error)
                    }
                    
                    loadResult = .failed(failureReason)
                case .success(let purchases):
                    loadResult = .succeeded(purchases)
            }
            
            DispatchQueue.main.async {
                completion(loadResult)
                fetchingStateChanged()
            }
        }
        
        task.start()
        
        self.availablePurchasesTask = task
        fetchingStateChanged()
    }
    
    private func refetchAvailablePurchases(silentlyFetch: Bool) {
        self.fetchPurchases(onFetchingStateChanged: { [weak self] in
            guard !silentlyFetch, let self = self else { return }

            self.delegate?.productInterfaceControllerDidChangeFetchingState(self)
        }, onCompletion: { [weak self] result in
            guard let self = self else { return }
            
            let didSucceed: Bool
            
            switch (self.availablePurchasesFetchResult, result) {
                case (.failed(_)?, .succeeded(_)):
                    didSucceed = true
                case (.succeeded(_)?, .succeeded(_)):
                    didSucceed = true
                case (nil, _):
                    didSucceed = true
                case (_, .failed(_)):
                    didSucceed = false
            }
            
            if didSucceed {
                self.availablePurchasesFetchResult = result

                self.didChangeState(for: self.products)
            }
        })
    }
    
    private func _determineCurrentState(for product: Product) -> ProductState {
        let state: ProductState
        let purchasedState = self.merchant.state(for: product)
        
        if case .isPurchased(let productInfo) = purchasedState {
            let purchaseMetadata: ProductState.PurchaseMetadata? = {
                switch self.availablePurchasesFetchResult {
                    case .succeeded(let purchases)?:
                        if let purchase = purchases.purchase(for: product) {
                            let subscriptionTerms: SubscriptionTerms?
                            
                            if #available(iOS 11.2, macOS 10.13.2, *) {
                                subscriptionTerms = purchase.subscriptionTerms
                            } else {
                                subscriptionTerms = nil
                            }
                            
                            return ProductState.PurchaseMetadata(
                                price: purchase.price,
                                subscriptionTerms: subscriptionTerms
                            )
                        }
                    default:
                        break
                }
                
                return nil
            }()
            
            state = .purchased(productInfo, purchaseMetadata)
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
    
    private func didChangeState(for products: Set<Product>) {
        var changedProducts = Set<Product>()
        
        for product in products {
            let currentState = self.state(for: product)
            let newState = self._determineCurrentState(for: product)
            
            if currentState != newState {
                self.stateForProductIdentifier[product.identifier] = newState
                
                changedProducts.insert(product)
            }
        }
        
        if !changedProducts.isEmpty {
            self.delegate?.productInterfaceController(self, didChangeStatesFor: changedProducts)
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
            DispatchQueue.main.async {
                self.refetchAvailablePurchases(silentlyFetch: true)
            }
        }
    }
}
