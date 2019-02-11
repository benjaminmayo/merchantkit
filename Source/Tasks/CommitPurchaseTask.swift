/// This task starts the purchase flow for a purchase discovered by a previous `AvailablePurchasesTask` callback.
public final class CommitPurchaseTask : MerchantTask {
    public let purchase: Purchase
    
    public var onCompletion: MerchantTaskCompletion<Void>!
    public private(set) var isStarted: Bool = false
    
    private unowned let merchant: Merchant
    
    /// Create a task by using the `Merchant.commitPurchaseTask(for:)` API.
    internal init(for purchase: Purchase, with merchant: Merchant) {
        self.purchase = purchase
        self.merchant = merchant
    }
    
    /// Start the task to begin committing the purchase. Call `start()` on the main thread.
    public func start() {
        self.assertIfStartedBefore()
        
        self.isStarted = true
        self.merchant.taskDidStart(self)
        
        self.merchant.addPurchaseObserver(self)
        
        self.merchant.storeInterface.commitPurchase(self.purchase, using: self.merchant.storeParameters)
        
        self.merchant.logger.log(message: "Started commit purchase task for product: \(self.purchase.productIdentifier)", category: .tasks)
    }
    
    /// Cancel the task. Cancellation does not fire the `onCompletion` handler.
    public func cancel() {
        self.merchant.removePurchaseObserver(self)
        
        self.merchant.taskDidResign(self)
    }
}

extension CommitPurchaseTask {
    private func finish(with result: Result<Void, Error>) {
        self.onCompletion(result)
        
        self.merchant.removePurchaseObserver(self)
        
        DispatchQueue.main.async {
            self.merchant.taskDidResign(self)
        }
        
        self.merchant.logger.log(message: "Finished commit purchase purchase task: \(result)", category: .tasks)
    }
}

extension CommitPurchaseTask : MerchantPurchaseObserver {
    internal func merchant(_ merchant: Merchant, didCompletePurchaseForProductWith productIdentifier: String) {
        if self.purchase.productIdentifier == productIdentifier {
            self.finish(with: .success)
        }
    }
    
    internal func merchant(_ merchant: Merchant, didFailPurchaseWith error: Error, forProductWith productIdentifier: String) {
        if self.purchase.productIdentifier == productIdentifier {
            self.finish(with: .failure(error))
        }
    }
    
    internal func merchant(_ merchant: Merchant, didCompleteRestoringPurchasesWith error: Error?) {
        
    }
}
