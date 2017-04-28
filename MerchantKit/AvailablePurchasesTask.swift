/// This task fetches possible purchases the user may wish to execute, and automatically excludes purchases the user has already purchased.
public final class AvailablePurchasesTask : NSObject, MerchantTask {
    public typealias Purchases = Set<Purchase>
    
    public var onCompletion: TaskCompletion<Purchases>!
    
    private unowned let merchant: Merchant
    private let products: Set<Product>
    private var skRequest: SKProductsRequest!
    
    // Create a task using the `Merchant.availablePurchasesTask(forProductIdentifiers(for:)` API. 
    internal init(for products: Set<Product>, with merchant: Merchant) {
        self.products = products
        self.merchant = merchant
    }
    
    public func start() {
        let identifiersForPurchasableProducts = self.products.filter {
            !self.merchant.state(for: $0).isPurchased
        }.map { $0.identifier }
        
        self.skRequest = SKProductsRequest(productIdentifiers: Set(identifiersForPurchasableProducts))
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
        
        let purchases: [Purchase] = skProducts.map(Purchase.init(from:))
        
        self.onCompletion(.succeeded(Set(purchases)))
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        self.onCompletion(.failed(error))
    }
}
