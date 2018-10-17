import StoreKit

internal protocol StoreKitTransactionObserverDelegate : AnyObject {
    func storeKitTransactionObserverWillUpdatePurchases(_ observer: StoreKitTransactionObserver)
    func storeKitTransactionObserverDidUpdatePurchases(_ observer: StoreKitTransactionObserver)
    
    func storeKitTransactionObserver(_ observer: StoreKitTransactionObserver, didPurchaseProductWith identifier: String)
    func storeKitTransactionObserver(_ observer: StoreKitTransactionObserver, didFailToPurchaseWith error: Error, forProductWith identifier: String)
}

/// Observes the payment queue for changes and notifies the delegate of significant updates.
internal final class StoreKitTransactionObserver : NSObject, SKPaymentTransactionObserver {
    public weak var delegate: StoreKitTransactionObserverDelegate?
    
    internal override init() {
        super.init()
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        self.delegate?.storeKitTransactionObserverWillUpdatePurchases(self)
        
        for transaction in transactions {            
            switch transaction.transactionState {
                case .purchased:
                    self.completePurchase(for: transaction)
                case .purchasing:
                    break
                case .restored:
                    self.completePurchase(for: transaction.original!)
                case .failed:
                    self.failPurchase(for: transaction)
                case .deferred:
                    break
            }
        }
        
        self.delegate?.storeKitTransactionObserverDidUpdatePurchases(self)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return true
    }
    
    private func completePurchase(for transaction: SKPaymentTransaction) {        
        self.delegate?.storeKitTransactionObserver(self, didPurchaseProductWith: transaction.payment.productIdentifier)
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func failPurchase(for transaction: SKPaymentTransaction) {
        self.delegate?.storeKitTransactionObserver(self, didFailToPurchaseWith: transaction.error!, forProductWith: transaction.payment.productIdentifier)
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
}
