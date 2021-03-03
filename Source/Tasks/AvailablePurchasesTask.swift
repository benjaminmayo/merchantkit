import Foundation

/// This task fetches possible purchases the user may wish to execute.
/// The fetched purchases can represent products that the user has already purchased. These should be filtered out by the client, if desired. If you are implementing a storefront UI in your app, you may want to use `ProductInterfaceController` rather than dealing with the lower-level tasks.
public final class AvailablePurchasesTask : MerchantTask {
    public typealias Purchases = PurchaseSet
    
    public let products: Set<Product>
    
    public var onCompletion: MerchantTaskCompletion<Purchases>!
    public private(set) var isStarted: Bool = false
    
    private unowned let merchant: Merchant
    
    private var availablePurchasesFetcher: AvailablePurchasesFetcher!
    
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
        
        self.availablePurchasesFetcher = self.merchant.storeInterface.makeAvailablePurchasesFetcher(for: self.products)
        self.availablePurchasesFetcher.enqueueCompletion({ [unowned self] result in
            self.finish(with: result)
        })
        
        self.availablePurchasesFetcher.start()
        
        self.merchant.logger.log(message: "Started available purchases task for products: \(self.products.map { $0.identifier })", category: .tasks)
    }
    
    /// Cancel the task. Cancellation does not fire the `onCompletion` handler.
    public func cancel() {
        self.availablePurchasesFetcher?.cancel()
        
        self.merchant.taskDidResign(self)
    }
    
    private func finish(with result: Result<Purchases, AvailablePurchasesFetcherError>) {
		let mapped = result.mapError { $0 as Error }
		
        self.onCompletion(mapped)
        
        DispatchQueue.main.async {
            self.merchant.taskDidResign(self)
        }
        
        self.merchant.logger.log(message: "Finished available purchases task: \(result)", category: .tasks)
    }
}
