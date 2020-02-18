import StoreKit

internal class StoreKitAvailablePurchasesFetcher : NSObject, AvailablePurchasesFetcher {
    internal typealias Completion = (Result<PurchaseSet, AvailablePurchasesFetcherError>) -> Void
    
    private let products: Set<Product>
    private let paymentQueue: SKPaymentQueue
	
    private var request: SKProductsRequest?
    
    private var completionHandlers = [Completion]()

    private var isFinished: Bool = false
    private var isCancelled: Bool = false
    
	internal required init(forProducts products: Set<Product>, paymentQueue: SKPaymentQueue) {
        self.products = products
		self.paymentQueue = paymentQueue
		
        super.init()
    }
    
    internal func enqueueCompletion(_ completion: @escaping Completion) {
        assert(!self.isFinished)
        
        self.completionHandlers.append(completion)
    }
    
    internal func start() {
		guard type(of: self.paymentQueue).canMakePayments() else {
			self.finish(with: .failure(.userNotAllowedToMakePurchases))
			
			return
		}
		
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
}

extension StoreKitAvailablePurchasesFetcher {
    private func finish(with result: Result<PurchaseSet, AvailablePurchasesFetcherError>) {
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
			let invalidProducts = Set(response.invalidProductIdentifiers.compactMap { invalidIdentifier in
				self.products.first(where: { $0.identifier == invalidIdentifier })
			})
			
			self.finish(with: .failure(.noAvailablePurchases(invalidProducts: invalidProducts)))
        } else {
            self.finish(with: .success(PurchaseSet(from: purchases)))
        }
    }
    
    internal func request(_ request: SKRequest, didFailWithError error: Swift.Error) {
		self.finish(with: .failure(.other(error)))
    }
}
