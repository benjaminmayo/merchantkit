/// This task restores previous purchases made by the signed-in user. Executing this task may present UI.
/// If using MerchantKit, it is important to use this task rather than manually invoking StoreKit.
public final class RestorePurchasesTask : MerchantTask {
    public typealias RestoredProducts = Set<Product>
    
    public var onCompletion: MerchantTaskCompletion<RestoredProducts>?
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

        self.merchant.addProductPurchaseObserver(self)
        self.merchant.storeInterface.restorePurchases(using: self.merchant.storeParameters)
        
        self.merchant.logger.log(message: "Started restore purchases", category: .tasks)
    }
}

extension RestorePurchasesTask {
    private func finish(with result: Result<RestoredProducts, Error>) {
        self.onCompletion?(result)
        
        self.merchant.removeProductPurchaseObserver(self)
        
        DispatchQueue.main.async {
            self.merchant.taskDidResign(self)
        }
        
        self.merchant.logger.log(message: "Finished restore purchases task: \(result)", category: .tasks)
    }
}

extension RestorePurchasesTask : MerchantProductPurchaseObserver {
    func merchant(_ merchant: Merchant, didFinishPurchaseWith result: Result<Void, Error>, forProductWith productIdentifier: String) {
        switch result {
            case .success(_):
                self.restoredProductIdentifiers.insert(productIdentifier)
            case .failure(_):
                break
        }
    }
    
    func merchant(_ merchant: Merchant, didCompleteRestoringProductsWith result: Result<Void, Error>) {
        let result: Result<RestoredProducts, Error> = result.map { _ in
            let restoredProducts = Set(self.restoredProductIdentifiers.compactMap { self.merchant.product(withIdentifier: $0) })

            return restoredProducts
        }
        
        self.finish(with: result)
    }
}
