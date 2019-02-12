import StoreKit

/// Observes the payment queue for changes and notifies the delegate of significant updates.
internal final class StoreKitTransactionObserver : NSObject {
    public weak var delegate: StoreInterfaceDelegate?
    
    private unowned let storeInterface: StoreInterface
    
    internal init(storeInterface: StoreInterface) {
        self.storeInterface = storeInterface
        
        super.init()
    }
    
    internal func start() {
        SKPaymentQueue.default().add(self)
    }
}

extension StoreKitTransactionObserver {
    fileprivate func completePurchase(for transaction: SKPaymentTransaction) {
        self.delegate?.storeInterface(self.storeInterface, didPurchaseProductWith: transaction.payment.productIdentifier, completion: {
            SKPaymentQueue.default().finishTransaction(transaction)
        })
    }
    
    fileprivate func completeRestorePurchase(for transaction: SKPaymentTransaction, original: SKPaymentTransaction) {
        self.delegate?.storeInterface(self.storeInterface, didRestorePurchaseForProductWith: original.payment.productIdentifier)
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    fileprivate func failPurchase(for transaction: SKPaymentTransaction) {
        self.delegate?.storeInterface(self.storeInterface, didFailToPurchaseProductWith: transaction.payment.productIdentifier, error: transaction.error!)
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
}

extension StoreKitTransactionObserver : SKPaymentTransactionObserver {
    internal func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        self.delegate?.storeInterfaceWillUpdatePurchases(self.storeInterface)
        
        for transaction in transactions {            
            switch transaction.transactionState {
                case .purchased:
                    self.completePurchase(for: transaction)
                case .purchasing:
                    break
                case .restored:
                    self.completeRestorePurchase(for: transaction, original: transaction.original!)
                case .failed:
                    self.failPurchase(for: transaction)
                case .deferred:
                    break
                @unknown default:
                    break
            }
        }
        
        self.delegate?.storeInterfaceDidUpdatePurchases(self.storeInterface)
    }
    
    internal func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        let response = self.delegate?.storeInterface(self.storeInterface, responseForStoreIntentToCommitPurchaseFrom: .pendingStorePayment(product, payment)) ?? .default
        
        switch response {
            case .automaticallyCommit:
                return true
            case .defer:
                return false
        }
    }
    
    internal func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        self.delegate?.storeInterface(self.storeInterface, didFinishRestoringPurchasesWith: .success)
    }
    
    internal func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        self.delegate?.storeInterface(self.storeInterface, didFinishRestoringPurchasesWith: .failure(error))
    }
}
