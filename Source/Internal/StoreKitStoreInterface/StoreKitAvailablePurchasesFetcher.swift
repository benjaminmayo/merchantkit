import StoreKit

internal class StoreKitAvailablePurchasesFetcher : NSObject, AvailablePurchasesFetcher {
    internal typealias Completion = (Result<PurchaseSet, Swift.Error>) -> Void
    
    private let products: Set<Product>
    
    private var request: SKProductsRequest?
    
    private var completionHandlers = [Completion]()

    private var isFinished: Bool = false
    private var isCancelled: Bool = false
    
    internal required init(forProducts products: Set<Product>) {
        self.products = products
        
        super.init()
    }
    
    internal func enqueueCompletion(_ completion: @escaping Completion) {
        assert(!self.isFinished)
        
        self.completionHandlers.append(completion)
    }
    
    internal func start() {
        let productIdentifiers = self.products.map { $0.identifier }
        
        self.request = {
            let request = SKProductsRequest(productIdentifiers: Set(productIdentifiers))
            request.delegate = self
            
            return request
        }()
        
        self.request?.start()
    }
    
    func cancel() {
        self.request?.cancel()
        self.isCancelled = true
        self.isFinished = true
    }
    
    enum Error : Swift.Error {
        case noAvailablePurchases(invalidProductIdentifiers: [String])
    }
}

extension StoreKitAvailablePurchasesFetcher {
    private func finish(with result: Result<PurchaseSet, Swift.Error>) {
        if self.isCancelled {
            return
        }
        
        assert(!self.isFinished)
        
        for handler in self.completionHandlers {
            handler(result)
        }
        
        self.isFinished = true
    }
}

extension StoreKitAvailablePurchasesFetcher : SKProductsRequestDelegate {
    internal func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let skProducts = response.products
        
        let purchases: [Purchase] = skProducts.compactMap { skProduct in
            guard let product = self.products.first(where: { $0.identifier == skProduct.productIdentifier }) else { return nil }
            
            return Purchase(from: .availableProduct(skProduct), for: product)
        }
        
        if purchases.isEmpty && !response.invalidProductIdentifiers.isEmpty {
            self.finish(with: .failure(Error.noAvailablePurchases(invalidProductIdentifiers: response.invalidProductIdentifiers)))
        } else {
            self.finish(with: .success(PurchaseSet(from: purchases)))
        }
    }
    
    internal func request(_ request: SKRequest, didFailWithError error: Swift.Error) {
        self.finish(with: .failure(error))
    }
}
