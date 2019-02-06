import StoreKit

/// This task fetches possible purchases the user may wish to execute.
/// The fetched purchases can represent products that the user has already purchased. These should be filtered out by the client, if desired. If you are implementing a storefront UI in your app, you may want to use `ProductInterfaceController` rather than dealing with the lower-level tasks.
public final class AvailablePurchasesTask : NSObject, MerchantTask {
    public typealias Purchases = PurchaseSet
    
    public var onCompletion: TaskCompletion<Purchases>!
    public private(set) var isStarted: Bool = false
    
    private unowned let merchant: Merchant
    private let products: Set<Product>
    private var skRequest: SKProductsRequest!
    
    /// Create a task using the `Merchant.availablePurchasesTask(for:)` API.
    internal init(for products: Set<Product>, with merchant: Merchant) {
        self.products = products
        self.merchant = merchant
    }
    
    /// Start the task to begin fetching purchases. Call `start()` on the main thread.
    public func start() {
        self.assertIfStartedBefore()
        
        self.isStarted = true
        self.merchant.taskDidStart(self)
        
        let productIdentifiers: [String] = self.products.map {
            $0.identifier
        }
        
        self.skRequest = SKProductsRequest(productIdentifiers: Set(productIdentifiers))
        self.skRequest.delegate = self
        
        self.skRequest.start()
        
        self.merchant.logger.log(message: "Started available purchases task for products: \(productIdentifiers)", category: .tasks)
    }
    
    /// Cancel the task. Cancellation does not fire the `onCompletion` handler.
    public func cancel() {
        self.skRequest?.cancel()
        
        self.merchant.taskDidResign(self)
    }
    
    private func finish(with result: Result<Purchases>) {
        self.onCompletion(result)
        
        DispatchQueue.main.async {
            self.merchant.taskDidResign(self)
        }
        
        self.merchant.logger.log(message: "Finished available purchases task: \(result)", category: .tasks)
    }
}

extension AvailablePurchasesTask : SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let skProducts = response.products
        
        let purchases: [Purchase] = skProducts.compactMap { skProduct in
            guard let product = self.products.first(where: { $0.identifier == skProduct.productIdentifier }) else { return nil }
            
            return Purchase(from: .availableProduct(skProduct), for: product)
        }
        
        self.finish(with: .succeeded(PurchaseSet(from: purchases)))
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        self.finish(with: .failed(error))
    }
}
