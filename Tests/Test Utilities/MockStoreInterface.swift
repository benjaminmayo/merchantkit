import Foundation
@testable import MerchantKit

internal class MockStoreInterface {
    internal var receiptFetchResult: Result<Data, Error>!
    internal var receiptFetchDelay: TimeInterval = 0.1

    internal var receiptFetchDidComplete: (() -> Void)?
    
    internal var availablePurchasesResult: Result<PurchaseSet, AvailablePurchasesFetcherError>!
    internal var didCommitPurchase: ((Purchase, PurchaseDiscount?) -> Void)?
    internal var restoredProductsResult: Result<Set<String>, Error>!
    
    private var delegate: StoreInterfaceDelegate?
    
    internal init() {
        
    }
    
    func dispatchCommitPurchaseEvent(forProductWith productIdentifier: String, result: Result<Void, Error>, afterDelay delay: TimeInterval = 0, on queue: DispatchQueue = .main) {
        queue.asyncAfter(deadline: .now() + delay, execute: {
            self.delegate?.storeInterfaceWillUpdatePurchases(self)
            
            switch result {
                case .success(_):
                    self.delegate?.storeInterface(self, didPurchaseProductWith: productIdentifier, completion: {})
                case .failure(let error):
                    self.delegate?.storeInterface(self, didFailToPurchaseProductWith: productIdentifier, error: error)
            }
            
            self.delegate?.storeInterfaceDidUpdatePurchases(self)
        })
    }
    
    func dispatchStoreIntentToCommitPurchase(from source: Purchase.Source) -> StoreIntentResponse {
        let response = self.delegate!.storeInterface(self, responseForStoreIntentToCommitPurchaseFrom: source)
        
        return response
    }
}

extension MockStoreInterface : StoreInterface {
    internal func makeReceiptFetcher(for policy: ReceiptFetchPolicy) -> ReceiptDataFetcher {
        let fetcher = MockReceiptDataFetcher(policy: policy, delay: self.receiptFetchDelay)
        fetcher.result = self.receiptFetchResult
        fetcher.enqueueCompletion({ _ in
            self.receiptFetchDidComplete?()
        })
        
        return fetcher
    }
    
    internal func setup(withDelegate delegate: StoreInterfaceDelegate) {
        self.delegate = delegate
    }
    
    internal func makeAvailablePurchasesFetcher(for products: Set<Product>) -> AvailablePurchasesFetcher {
        let fetcher = MockAvailablePurchasesFetcher(forProducts: products)
        fetcher.result = self.availablePurchasesResult
        
        return fetcher
    }
    
    internal func commitPurchase(_ purchase: Purchase, with discount: PurchaseDiscount?, using storeParameters: StoreParameters) {
        self.didCommitPurchase?(purchase, discount)
    }
    
    internal func restorePurchases(using storeParameters: StoreParameters) {
        self.delegate?.storeInterfaceWillStartRestoringPurchases(self)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            for productIdentifier in (try? self.restoredProductsResult!.get()) ?? [] {
                self.delegate?.storeInterface(self, didRestorePurchaseForProductWith: productIdentifier)
            }
            
            self.delegate?.storeInterface(self, didFinishRestoringPurchasesWith: self.restoredProductsResult.map { _ in () })
        })
    }
}

private class MockAvailablePurchasesFetcher : AvailablePurchasesFetcher {
    private let products: Set<Product>
    
    typealias Completion = (Result<PurchaseSet, AvailablePurchasesFetcherError>) -> Void
    
    private var completionHandlers = [Completion]()
    
    private var isFinished: Bool = false
    private var isCancelled: Bool = false
    
    var result: Result<PurchaseSet, AvailablePurchasesFetcherError>!

    
    required init(forProducts products: Set<Product>) {
        self.products = products
    }
    
    func enqueueCompletion(_ completion: @escaping Completion) {
        self.completionHandlers.append(completion)
    }
    
    func start() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            assert(!self.isFinished, "Fetcher can only be completed once.")
            
            guard !self.isCancelled else { return }
            
            for handler in self.completionHandlers {
                handler(self.result)
            }
            
            self.isFinished = true
        })
    }
    
    func cancel() {
        self.isCancelled = true
    }
}

private class MockReceiptDataFetcher : ReceiptDataFetcher {
    private var completionBlocks = [Completion]()
    
    typealias Completion = (Result<Data, Error>) -> Void
    
    var result: Result<Data, Error>!
    private let delay: TimeInterval
    
    required init(policy: ReceiptFetchPolicy, delay: TimeInterval) {
        self.delay = delay
    }
    
    func enqueueCompletion(_ completion: @escaping Completion) {
        self.completionBlocks.append(completion)
    }
    
    func start() {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.delay, execute: {
            for block in self.completionBlocks {
                block(self.result)
            }
        })
    }
    
    func cancel() {
        
    }
}
