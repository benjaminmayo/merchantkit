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
/// Create a controller and call `fetchDataIfNecessary()` when the user interface is presented. Update UI in response to state changes, via the `delegate`.
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
    
    private var availablePurchasesFetchResult: FetchResult<PurchaseSet>?
    
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
        guard self.availablePurchasesFetchResult == nil else { return }
        
        self.fetchPurchases(onFetchingStateChanged: { [weak self] in self?.didChangeFetchingState() }, onCompletion: { [weak self] result in
            guard let strongSelf = self else { return }
            
            strongSelf.availablePurchasesFetchResult = result
            
            strongSelf.didChangeState(for: strongSelf.products)
        })
    }
    
    /// Purchase a `Product` managed by this controller.
    public func commit(_ purchase: Purchase) {
        guard let product = self.products.first(where: { product in
            product.identifier == purchase.productIdentifier
        }) else { MerchantKitFatalError.raise("committing incompatible purchase") }
        
        let task = self.merchant.commitPurchaseTask(for: purchase)
        task.onCompletion = { result in
            self.commitPurchaseTask = nil
            
            self.didChangeState(for: [product])
            
            switch result {
                case .succeeded(_):
                    DispatchQueue.main.async {
                        self.delegate?.productInterfaceController(self, didCommit: purchase, with: .succeeded)
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
                    self.delegate?.productInterfaceController(self, didCommit: purchase, with: .failed(error, shouldDisplayError: shouldDisplayError))
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
            guard let strongSelf = self else { return }
            
            strongSelf.restorePurchasesTask = nil
            
            let restoreResult: RestorePurchasesResult
            
            switch result {
                case .succeeded(let restoredProducts):
                    let updatedProducts = strongSelf.products.intersection(restoredProducts)
                    strongSelf.didChangeState(for: updatedProducts)
                
                    restoreResult = .succeeded(updatedProducts)
                case .failed(let error):
                    restoreResult = .failed(error)
            }
            
            DispatchQueue.main.async {
                strongSelf.delegate?.productInterfaceController(strongSelf, didRestorePurchasesWith: restoreResult)
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

extension ProductInterfaceController {
    private enum FetchResult<T> {
        case succeeded(T)
        case failed(FetchingState.FailureReason)
    }
    
    private func fetchPurchases(onFetchingStateChanged fetchingStateChanged: @escaping () -> Void, onCompletion completion: @escaping (FetchResult<PurchaseSet>) -> Void) {
        let task = self.merchant.availablePurchasesTask(for: self.products)
        task.onCompletion = { [weak self] result in
            guard let strongSelf = self else { return }
            
            strongSelf.availablePurchasesTask = nil
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
        self.fetchPurchases(onFetchingStateChanged: {}, onCompletion: { [weak self] result in
            guard let strongSelf = self else { return }
            
            let didChange: Bool
            
            switch (strongSelf.availablePurchasesFetchResult, result) {
                case (.failed(_)?, .succeeded(_)):
                    strongSelf.availablePurchasesFetchResult = result
                    didChange = true
                case (.succeeded(_)?, .succeeded(_)):
                    strongSelf.availablePurchasesFetchResult = result
                    didChange = true
                case (nil, _):
                    strongSelf.availablePurchasesFetchResult = result
                    didChange = true
                case (_, .failed(_)):
                    didChange = false
            }
            
            if didChange {
                strongSelf.didChangeState(for: strongSelf.products)
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
                            
                            if #available(iOS 11.2, *) {
                                subscriptionTerms = purchase.subscriptionTerms
                            } else {
                                subscriptionTerms = nil
                            }
                            
                            return ProductState.PurchaseMetadata(price: purchase.price, subscriptionTerms: subscriptionTerms)
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
    
    private func didChangeFetchingState() {
        DispatchQueue.main.async {
            self.delegate?.productInterfaceControllerDidChangeFetchingState(self)
        }
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
            DispatchQueue.main.async {
                self.delegate?.productInterfaceController(self, didChangeStatesFor: changedProducts)
            }
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
        
        self.fetchPurchases(onFetchingStateChanged: {}, onCompletion: { [weak self] result in
            guard let strongSelf = self else { return }
            
            strongSelf.availablePurchasesFetchResult = result
            
            strongSelf.didChangeState(for: strongSelf.products)
        })
    }
}
