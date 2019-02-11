internal class StoreKitStoreInterface : StoreInterface {
    private let transactionObserver = StoreKitTransactionObserver()
    
    internal func makeReceiptFetcher(for policy: ReceiptFetchPolicy) -> ReceiptDataFetcher {
        return StoreKitReceiptDataFetcher(policy: policy)
    }
    
    internal func observeTransactions(withDelegate delegate: StoreKitTransactionObserverDelegate) {
        self.transactionObserver.delegate = delegate
        
        SKPaymentQueue.default().add(self.transactionObserver)
    }
    
    internal func stopObservingTransactions() {
        SKPaymentQueue.default().remove(self.transactionObserver)
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
