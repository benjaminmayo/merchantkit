import Foundation

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

        self.merchant.storePurchaseObservers.add(self, forObserving: \.restorePurchasedProducts)
        
        self.merchant.storeInterface.restorePurchases(using: self.merchant.storeParameters)
        
        self.merchant.logger.log(message: "Started restore purchases", category: .tasks)
    }
}

extension RestorePurchasesTask {
    private func finish(with result: Result<RestoredProducts, Error>) {
        self.onCompletion?(result)
        
        self.merchant.storePurchaseObservers.remove(self, forObserving: \.restorePurchasedProducts)
        
        DispatchQueue.main.async {
            self.merchant.taskDidResign(self)
        }
        
        self.merchant.logger.log(message: "Finished restore purchases task: \(result)", category: .tasks)
    }
}

extension RestorePurchasesTask : Merchant.StorePurchaseObservers.RestorePurchasedProductsObserver {
    func merchantDidStartRestoringProducts(_ merchant: Merchant) {
        
    }
    
    func merchant(_ merchant: Merchant, didRestorePurchasedProductWith productIdentifier: String) {
        self.restoredProductIdentifiers.insert(productIdentifier)
    }
    
    func merchant(_ merchant: Merchant, didFinishRestoringProductsWith result: Result<Void, Error>) {
        let result: Result<RestoredProducts, Error> = result.map { _ in
            let restoredProducts = Set(self.restoredProductIdentifiers.compactMap { self.merchant.product(withIdentifier: $0) })

            return restoredProducts
        }
        
        self.finish(with: result)
    }
}
