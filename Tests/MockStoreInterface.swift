internal class MockStoreInterface : StoreInterface {
    internal var receiptFetchResult: Result<Data, Error>!
    internal var availablePurchasesResult: Result<PurchaseSet, Error>!
    
    internal init() {
        
    }
    
    internal func makeReceiptFetcher(for policy: ReceiptFetchPolicy) -> ReceiptDataFetcher {
        let fetcher = MockReceiptDataFetcher(policy: policy)
        fetcher.result = self.receiptFetchResult
        
        return fetcher
    }
    
    internal func setup(withDelegate delegate: StoreInterfaceDelegate) {
        
    }
    
    internal func makeAvailablePurchasesFetcher(for products: Set<Product>) -> AvailablePurchasesFetcher {
        let fetcher = MockAvailablePurchasesFetcher(forProducts: products)
        fetcher.result = self.availablePurchasesResult
        
        return fetcher
    }
    
    internal func commitPurchase(_ purchase: Purchase, using storeParameters: StoreParameters) {
        fatalError()
    }
    
    internal func restorePurchases(using storeParameters: StoreParameters) {
        fatalError()
    }
}

private class MockAvailablePurchasesFetcher : AvailablePurchasesFetcher {
    private let products: Set<Product>
    
    typealias Completion = (Result<PurchaseSet, Error>) -> Void
    
    private var completionHandlers = [Completion]()
    
    private var isFinished: Bool = false
    private var isCancelled: Bool = false
    
    var result: Result<PurchaseSet, Error>!
    
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
    
    required init(policy: ReceiptFetchPolicy) {
        
    }
    
    func enqueueCompletion(_ completion: @escaping Completion) {
        self.completionBlocks.append(completion)
    }
    
    func start() {
        for block in self.completionBlocks {
            block(self.result)
        }
    }
    
    func cancel() {
        
    }
}
