import Foundation 
import StoreKit

/// This task starts the purchase flow for a purchase discovered by a previous `AvailablePurchasesTask` callback.
public final class CommitPurchaseTask : MerchantTask {
    public let purchase: Purchase
    
    public var onCompletion: TaskCompletion<Void>!
    public private(set) var isStarted: Bool = false
    
    private unowned let merchant: Merchant
    
    /// Create a task by using the `Merchant.commitPurchaseTask(for:)` API.
    internal init(for purchase: Purchase, with merchant: Merchant) {
        self.purchase = purchase
        self.merchant = merchant
    }
    
    public func start() {
        self.assertIfStartedBefore()
        
        self.isStarted = true
        self.merchant.updateActiveTask(self)
        
        self.merchant.addPurchaseObserver(self, forProductIdentifier: self.purchase.productIdentifier)
        
        let payment = SKMutablePayment(product: self.purchase.skProduct)
        payment.applicationUsername = self.merchant.storeParameters.applicationUsername
        
        SKPaymentQueue.default().add(payment)
    }
    
    /// Cancel the task. Cancellation does not fire the `onCompletion` handler.
    public func cancel() {
        self.merchant.removePurchaseObserver(self, forProductIdentifier: self.purchase.productIdentifier)
        
        self.merchant.resignActiveTask(self)
    }
}

extension CommitPurchaseTask {
    private func finish(with result: Result<Void>) {
        self.onCompletion(result)
        
        self.merchant.removePurchaseObserver(self, forProductIdentifier: self.purchase.productIdentifier)
        
        DispatchQueue.main.async {
            self.merchant.resignActiveTask(self)
        }
    }
}

extension CommitPurchaseTask : MerchantPurchaseObserver {
    func merchant(_ merchant: Merchant, didCompletePurchaseForProductWith productIdentifier: String) {        
        self.finish(with: .succeeded(()))
    }
    
    func merchant(_ merchant: Merchant, didFailPurchaseWith error: Error, forProductWith productIdentifier: String) {
        self.finish(with: .failed(error))
    }
}
