/// Restore completed purchases made by a user in the past. Executing this target may present UI.
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
    
    public func start() {
        self.assertIfStartedBefore()
        
        self.isStarted = true
        self.merchant.updateActiveTask(self)
        
        self.merchant.restorePurchases(completion: { updatedProducts, error in
            if let error = error {
                self.onCompletion?(.failed(error))
            } else {
                self.onCompletion?(.succeeded(updatedProducts))
            }
            
            DispatchQueue.main.async {
                self.merchant.resignActiveTask(self)
            }
        })
    }
}
