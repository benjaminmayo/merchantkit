public final class RestorePurchasesTask : MerchantTask {
    public var onCompletion: TaskCompletion<Set<Product>>?
    
    private unowned let merchant: Merchant
    
    internal init(with merchant: Merchant) {
        self.merchant = merchant
    }
    
    public func start() {
        self.merchant.restorePurchases(completion: { updatedProducts, error in
            if let error = error {
                self.onCompletion?(.failed(error))
            } else {
                self.onCompletion?(.succeeded(updatedProducts))
                self.merchant.resignActiveTask(self)
            }
        })
    }
}
