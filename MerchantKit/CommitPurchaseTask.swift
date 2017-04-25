import StoreKit

public final class CommitPurchaseTask : MerchantTask {
    public let purchase: Purchase
    
    public var onCompletion: TaskCompletion<Product>!
    
    private unowned let merchant: Merchant
    
    internal init(for purchase: Purchase, with merchant: Merchant) {
        self.purchase = purchase
        self.merchant = merchant
    }
    
    func start() {
        let payment = SKPayment(product: self.purchase.skProduct)
        SKPaymentQueue.default().add(payment)
    }
}
