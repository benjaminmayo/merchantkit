import Foundation

/// This task starts the purchase flow for a purchase discovered by a previous `AvailablePurchasesTask` callback.
public final class CommitPurchaseTask : MerchantTask {
    public let purchase: Purchase
    public let discount: PurchaseDiscount?
    
    public var onCompletion: MerchantTaskCompletion<Void>!
    public private(set) var isStarted: Bool = false
    
    private unowned let merchant: Merchant
    
    /// Create a task by using the `Merchant.commitPurchaseTask(for:)` API.
    internal init(for purchase: Purchase, applying discount: PurchaseDiscount?, with merchant: Merchant) {
        self.purchase = purchase
        self.discount = discount
        self.merchant = merchant
    }
    
    /// Start the task to begin committing the purchase. Call `start()` on the main thread.
    public func start() {
        self.assertIfStartedBefore()
        
        self.isStarted = true
        self.merchant.taskDidStart(self)
        
        self.merchant.storePurchaseObservers.add(self, forObserving: \.purchaseProducts)
        
        self.merchant.storeInterface.commitPurchase(self.purchase, with: self.discount, using: self.merchant.storeParameters)
        
        self.merchant.logger.log(message: "Started commit purchase task for product: \(self.purchase.productIdentifier)", category: .tasks)
    }
}

extension CommitPurchaseTask {
    private func finish(with result: Result<Void, Error>) {
        self.onCompletion(result)
        
        self.merchant.storePurchaseObservers.remove(self, forObserving: \.purchaseProducts)
        
        DispatchQueue.main.async {
            self.merchant.taskDidResign(self)
        }
        
        self.merchant.logger.log(message: "Finished commit purchase purchase task: \(result)", category: .tasks)
    }
}

extension CommitPurchaseTask : Merchant.StorePurchaseObservers.PurchaseProductsObserver {
    func merchant(_ merchant: Merchant, didFinishPurchaseWith result: Result<Void, Error>, forProductWith productIdentifier: String) {
        guard self.purchase.productIdentifier == productIdentifier else { return }
        
        self.finish(with: result)
    }
}
