import StoreKit

public final class AvailablePurchasesTask : MerchantTask {
    typealias Completion = (Set<Purchase>) -> Void
    
    internal unowned let merchant: Merchant
    
    private var skRequest: SKProductsRequest!
    
    internal init(for merchant: Merchant) {
        self.merchant = merchant
    }
    
    public func start() {
        let products = self.merchant.registeredProducts.filter {
            !self.merchant.state(forProductWithIdentifier: $0.identifier).isPurchased
        }
        let productIdentifiers = Set(products.map { $0.identifier})
        
        self.skRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
    }
}
