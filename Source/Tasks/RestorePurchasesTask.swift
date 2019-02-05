/// This task restores previous purchases made by the signed-in user. Executing this task may present UI.
/// If using MerchantKit, it is important to use this task rather than manually invoking StoreKit.
public final class RestorePurchasesTask : MerchantTask {
    public typealias RestoredPurchases = Set<Product>
    
    public var onCompletion: TaskCompletion<RestoredPurchases>?
    public private(set) var isStarted: Bool = false
    
    private unowned let merchant: Merchant
    
    /// Create a task using the `Merchant.restorePurchasesTask()` API.
    internal init(with merchant: Merchant) {
        self.merchant = merchant
    }
    
    /// Start the task to begin restoring purchases. Call `start()` on the main thread.
    public func start() {
        self.assertIfStartedBefore()
        
        self.isStarted = true
        self.merchant.taskDidStart(self)
        
        self.merchant.logger.log(message: "Started restore purchases", category: .tasks)

        self.merchant.restorePurchases(completion: { updatedProducts, error in
            let result: Result<RestoredPurchases, Error>
            
            if let error = error {
                result = .failure(error)
            } else {
                result = .success(updatedProducts)
            }
            
            self.onCompletion?(result)
            
            DispatchQueue.main.async {
                self.merchant.taskDidResign(self)
            }
            
            self.merchant.logger.log(message: "Finished restore purchases task: \(result)", category: .tasks)
        })
    }
}
