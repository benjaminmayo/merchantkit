import StoreKit

/// Observes the payment queue for changes and notifies the delegate of significant updates.
internal final class StoreKitTransactionObserver : NSObject {
    internal weak var delegate: StoreInterfaceDelegate?
    
    private unowned let storeInterface: StoreInterface
    private let paymentQueue: SKPaymentQueue
    
    internal init(storeInterface: StoreInterface, paymentQueue: SKPaymentQueue) {
        self.storeInterface = storeInterface
        self.paymentQueue = paymentQueue
        
        super.init()
    }
    
    internal func start() {
        self.paymentQueue.add(self)
    }
}

extension StoreKitTransactionObserver {
    fileprivate func completePurchase(for transaction: SKPaymentTransaction, on paymentQueue: SKPaymentQueue) {
        self.delegate?.storeInterface(self.storeInterface, didPurchaseProductWith: transaction.payment.productIdentifier, completion: {
            paymentQueue.finishTransaction(transaction)
        })
    }
    
    fileprivate func completeRestorePurchase(for transaction: SKPaymentTransaction, original: SKPaymentTransaction?, on paymentQueue: SKPaymentQueue) {
        self.delegate?.storeInterface(self.storeInterface, didRestorePurchaseForProductWith: transaction.payment.productIdentifier)
        
        paymentQueue.finishTransaction(transaction)
    }
    
    fileprivate func failPurchase(for transaction: SKPaymentTransaction, on paymentQueue: SKPaymentQueue) {
        self.delegate?.storeInterface(self.storeInterface, didFailToPurchaseProductWith: transaction.payment.productIdentifier, error: transaction.error!)
        
        paymentQueue.finishTransaction(transaction)
    }
}

extension StoreKitTransactionObserver : SKPaymentTransactionObserver {
    internal func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        self.delegate?.storeInterfaceWillUpdatePurchases(self.storeInterface)
        
        for transaction in transactions {
            switch transaction.transactionState {
                case .purchased:
                    self.completePurchase(for: transaction, on: queue)
                case .purchasing:
                    break
                case .restored:
                    self.completeRestorePurchase(for: transaction, original: transaction.original, on: queue)
                case .failed:
                    self.failPurchase(for: transaction, on: queue)
                case .deferred:
                    break
                @unknown default:
                    break
            }
        }
        
        self.delegate?.storeInterfaceDidUpdatePurchases(self.storeInterface)
    }
    
    #if os(iOS)
    internal func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        let response = self.delegate?.storeInterface(self.storeInterface, responseForStoreIntentToCommitPurchaseFrom: .pendingStorePayment(product, payment)) ?? .default
        
        switch response {
            case .automaticallyCommit:
                return true
            case .defer:
                return false
        }
    }
    #endif
    
    internal func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        self.delegate?.storeInterface(self.storeInterface, didFinishRestoringPurchasesWith: .success)
    }
    
    internal func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        self.delegate?.storeInterface(self.storeInterface, didFinishRestoringPurchasesWith: .failure(error))
    }
}
