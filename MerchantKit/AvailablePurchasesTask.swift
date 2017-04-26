/// This task fetches possible purchases the user may wish to execute, and automatically excludes purchases the user has already purchased.
public final class AvailablePurchasesTask : NSObject, MerchantTask {
    public typealias Purchases = Set<Purchase>
    
    public var onCompletion: TaskCompletion<Purchases>!
    
    private unowned let merchant: Merchant
    private let requestedProductIdentifiers: Set<String>
    private var skRequest: SKProductsRequest!
    
    // Create a task using the `Merchant.availablePurchasesTask(forProductIdentifiers(for:)` API. 
    internal init(forProductIdentifiers productIdentifiers: Set<String>, with merchant: Merchant) {
        self.requestedProductIdentifiers = productIdentifiers
        self.merchant = merchant
    }
    
    public func start() {
        let productIdentifiers = self.requestedProductIdentifiers.isEmpty ? Set(self.merchant.registeredProducts.map { $0.identifier }) : self.requestedProductIdentifiers
        let purchasableProductIdentifiers = Set(productIdentifiers.filter {
            !self.merchant.state(forProductWithIdentifier: $0).isPurchased
        })
        
        self.skRequest = SKProductsRequest(productIdentifiers: purchasableProductIdentifiers)
        self.skRequest.delegate = self
        
        self.skRequest.start()
    }
    
    /// Cancel the task. Cancellation does not fire the `onCompletion` handler.
    public func cancel() {
        self.skRequest?.cancel()
        
        self.merchant.resignActiveTask(self)
    }
    
    private func finish(with result: Result<Purchases>) {
        self.onCompletion(result)
        
        self.merchant.resignActiveTask(self)
    }
}

extension AvailablePurchasesTask : SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let skProducts = response.products
        
        let purchases: [Purchase] = skProducts.map { skProduct in
            let price = Price(from: skProduct.price, in: skProduct.priceLocale)
            
            return Purchase(productIdentifier: skProduct.productIdentifier, price: price, skProduct: skProduct)
        }
        
        self.onCompletion(.succeeded(Set(purchases)))
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        self.onCompletion(.failed(error))
    }
}
