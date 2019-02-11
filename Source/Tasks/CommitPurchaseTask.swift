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
        
        self.merchant.addProductPurchaseObserver(self)
        
        self.merchant.storeInterface.commitPurchase(self.purchase, using: self.merchant.storeParameters)
        
        self.merchant.logger.log(message: "Started commit purchase task for product: \(self.purchase.productIdentifier)", category: .tasks)
    }
    
    /// Cancel the task. Cancellation does not fire the `onCompletion` handler.
    public func cancel() {
        self.merchant.removeProductPurchaseObserver(self)
        
        self.merchant.taskDidResign(self)
    }
}

extension CommitPurchaseTask {
    private func finish(with result: Result<Void, Error>) {
        self.onCompletion(result)
        
        self.merchant.removeProductPurchaseObserver(self)
        
        DispatchQueue.main.async {
            self.merchant.taskDidResign(self)
        }
        
        self.merchant.logger.log(message: "Finished commit purchase purchase task: \(result)", category: .tasks)
    }
}

extension CommitPurchaseTask : MerchantProductPurchaseObserver {
    func merchant(_ merchant: Merchant, didFinishPurchaseWith result: Result<Void, Error>, forProductWith productIdentifier: String) {
        guard self.purchase.productIdentifier == productIdentifier else { return }
        
        self.finish(with: result)
    }
    
    func merchant(_ merchant: Merchant, didCompleteRestoringProductsWith result: Result<Void, Error>) {
        
    }
}
