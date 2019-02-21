import StoreKit

internal class MockSKPaymentTransaction : SKPaymentTransaction {
    private var _transactionIdentifier: String
    private var _transactionState: SKPaymentTransactionState
    private var _error: Error?
    private var _original: SKPaymentTransaction?
    private var _payment: SKPayment
    
    init(transactionIdentifier: String, transactionState: SKPaymentTransactionState, error: Error?, original: SKPaymentTransaction?, payment: SKPayment) {
        self._transactionIdentifier = transactionIdentifier
        self._transactionState = transactionState
        self._error = error
        self._original = original
        self._payment = payment
    }
    
    override var transactionIdentifier: String? {
        return self._transactionIdentifier
    }
    
    override var transactionState: SKPaymentTransactionState {
        return self._transactionState
    }
    
    override var error: Error? {
        return self._error
    }
    
    override var original: SKPaymentTransaction? {
        return self._original
    }
    
    override var payment: SKPayment {
        return self._payment
    }
}
