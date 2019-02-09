/// This task restores previous purchases made by the signed-in user. Executing this task may present UI.
/// If using MerchantKit, it is important to use this task rather than manually invoking StoreKit.
public final class RestorePurchasesTask : MerchantTask {
    public typealias RestoredPurchases = Set<Product>
    
    public var onCompletion: TaskCompletion<RestoredPurchases>?
    public private(set) var isStarted: Bool = false
    
    private unowned let merchant: Merchant
    
    private var restoredProductIdentifiers = Set<String>()
    
    /// Create a task using the `Merchant.restorePurchasesTask()` API.
    internal init(with merchant: Merchant) {
        self.merchant = merchant
    }
    
    /// Start the task to begin restoring purchases. Call `start()` on the main thread.
    public func start() {
        self.assertIfStartedBefore()
        
        self.isStarted = true
        self.merchant.taskDidStart(self)

        let applicationUsername = self.merchant.storeParameters.applicationUsername.isEmpty ? nil : self.merchant.storeParameters.applicationUsername
        
        self.merchant.addPurchaseObserver(self)
        
        SKPaymentQueue.default().restoreCompletedTransactions(withApplicationUsername: applicationUsername)
        
        self.merchant.logger.log(message: "Started restore purchases", category: .tasks)
    }
}

extension RestorePurchasesTask {
    private func finish(with result: Result<RestoredPurchases, Error>) {
        self.onCompletion?(result)
        
        self.merchant.removePurchaseObserver(self)
        
        DispatchQueue.main.async {
            self.merchant.taskDidResign(self)
        }
        
        self.merchant.logger.log(message: "Finished restore purchases task: \(result)", category: .tasks)
    }
}

extension RestorePurchasesTask : MerchantPurchaseObserver {
    func merchant(_ merchant: Merchant, didCompletePurchaseForProductWith productIdentifier: String) {
        self.restoredProductIdentifiers.insert(productIdentifier)
    }
    
    func merchant(_ merchant: Merchant, didFailPurchaseWith error: Error, forProductWith productIdentifier: String) {
        
    }
    
    func merchant(_ merchant: Merchant, didCompleteRestoringPurchasesWith error: Error?) {
        if let error = error {
            self.finish(with: .failed(error))
        } else {
            let restoredProducts = Set(self.restoredProductIdentifiers.compactMap { self.merchant.product(withIdentifier: $0) })
            
            self.finish(with: .succeeded(restoredProducts))
        }
    }
}
