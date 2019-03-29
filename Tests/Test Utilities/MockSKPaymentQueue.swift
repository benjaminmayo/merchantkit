import StoreKit

internal class MockSKPaymentQueue : SKPaymentQueue {
    internal var observers = [SKPaymentTransactionObserver]()
    
    internal override init() {
        super.init()
    }
    
    override func add(_ observer: SKPaymentTransactionObserver) {
        self.observers.append(observer)
    }
    
    override func restoreCompletedTransactions() {
        
    }
    
    override func restoreCompletedTransactions(withApplicationUsername username: String?) {
        
    }

    override func finishTransaction(_ transaction: SKPaymentTransaction) {
        
    }
}
