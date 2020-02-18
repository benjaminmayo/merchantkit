import StoreKit

internal class StoreKitStoreInterface : StoreInterface {
    private let paymentQueue: SKPaymentQueue
    private var transactionObserver: StoreKitTransactionObserver!
    
    fileprivate var delegate: StoreInterfaceDelegate? {
        didSet {
            self.transactionObserver.delegate = self.delegate
        }
    }
    
    internal init(paymentQueue: SKPaymentQueue) {
        self.paymentQueue = paymentQueue
        
        self.transactionObserver = StoreKitTransactionObserver(storeInterface: self, paymentQueue: self.paymentQueue)
    }
    
    internal func setup(withDelegate delegate: StoreInterfaceDelegate) {
        self.delegate = delegate
        
        self.transactionObserver.start()
    }

    internal func makeReceiptFetcher(for policy: ReceiptFetchPolicy) -> ReceiptDataFetcher {
        return StoreKitReceiptDataFetcher(policy: policy)
    }
    
    internal func makeAvailablePurchasesFetcher(for products: Set<Product>) -> AvailablePurchasesFetcher {
		return StoreKitAvailablePurchasesFetcher(forProducts: products, paymentQueue: self.paymentQueue)
    }
    
    internal func commitPurchase(_ purchase: Purchase, with discount: PurchaseDiscount?, using storeParameters: StoreParameters) {
        let payment: SKPayment
        
        switch purchase.source {
            case .availableProduct(let product):
                payment = self.payment(forAvailableProduct: product, with: discount, using: storeParameters)
            case .pendingStorePayment(_, let pendingPayment):
                payment = pendingPayment
        }
        
        self.paymentQueue.add(payment)
    }
    
    internal func restorePurchases(using storeParameters: StoreParameters) {
        self.delegate?.storeInterfaceWillStartRestoringPurchases(self)
        
        self.paymentQueue.restoreCompletedTransactions(withApplicationUsername: storeParameters.applicationUsername.nonEmpty)
    }
}

extension StoreKitStoreInterface {
    private func payment(forAvailableProduct product: SKProduct, with discount: PurchaseDiscount? = nil, using storeParameters: StoreParameters) -> SKPayment {
        let payment = SKMutablePayment(product: product)
        payment.applicationUsername = storeParameters.applicationUsername.nonEmpty
        
        if let discount = discount, #available(iOS 12.2, macOS 10.14.4, *) {
            payment.paymentDiscount = SKPaymentDiscount(identifier: discount.offerIdentifier, keyIdentifier: discount.keyIdentifier, nonce: discount.nonce, signature: discount.signature, timestamp: NSNumber(value: discount.timestamp))
        }
        
        return payment
    }
}
