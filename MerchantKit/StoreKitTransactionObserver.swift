import StoreKit

internal class StoreKitTransactionObserver : NSObject, SKPaymentTransactionObserver {
    internal override init() {
        super.init()
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                self.completePurchase(for: transaction)
            case .purchasing:
                break
            case .restored:
                self.completePurchase(for: transaction.original!)
            case .failed:
                break
            case .deferred:
                break
            }
        }
    }
    
    private func completePurchase(for transaction: SKPaymentTransaction) {
        
    }
}
