import StoreKit

internal class StoreKitStoreInterface : StoreInterface {
    private var transactionObserver: StoreKitTransactionObserver!
    fileprivate var delegate: StoreInterfaceDelegate? {
        didSet {
            self.transactionObserver.delegate = self.delegate
        }
    }
    
    internal init() {
        self.transactionObserver = StoreKitTransactionObserver(storeInterface: self)
    }
    
    internal func setup(withDelegate delegate: StoreInterfaceDelegate) {
        self.delegate = delegate
        
        self.transactionObserver.start()
    }

    internal func makeReceiptFetcher(for policy: ReceiptFetchPolicy) -> ReceiptDataFetcher {
        return StoreKitReceiptDataFetcher(policy: policy)
    }
    
    internal func makeAvailablePurchasesFetcher(for products: Set<Product>) -> AvailablePurchasesFetcher {
        return StoreKitAvailablePurchasesFetcher(forProducts: products)
    }
    
    internal func commitPurchase(_ purchase: Purchase, using storeParameters: StoreParameters) {
        let payment: SKPayment
        
        switch purchase.source {
            case .availableProduct(let product):
                payment = self.payment(forAvailableProduct: product, using: storeParameters)
            case .pendingStorePayment(_, let pendingPayment):
                payment = pendingPayment
        }
        
        SKPaymentQueue.default().add(payment)
    }
    
    internal func restorePurchases(using storeParameters: StoreParameters) {
        self.delegate?.storeInterfaceWillStartRestoringPurchases(self)
        
        SKPaymentQueue.default().restoreCompletedTransactions(withApplicationUsername: storeParameters.applicationUsername.nonEmpty)
    }
}

extension StoreKitStoreInterface {
    private func payment(forAvailableProduct product: SKProduct, using storeParameters: StoreParameters) -> SKPayment {
        let payment = SKMutablePayment(product: product)
        payment.applicationUsername = storeParameters.applicationUsername.nonEmpty
        
        return payment
    }
}
