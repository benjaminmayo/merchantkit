import StoreKit

public final class AvailablePurchasesTask : NSObject, MerchantTask {
    public typealias Purchases = Set<Purchase>
    
    public var onCompletion: TaskCompletion<Purchases>!
    
    private unowned let merchant: Merchant
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
        self.skRequest.delegate = self
        
        self.skRequest.start()
    }
    
    private func finish(with result: TaskResult<Purchases>) {
        self.onCompletion(result)
        
        self.merchant.resignActiveTask(self)
    }
}

extension AvailablePurchasesTask : SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let skProducts = response.products
        
        let purchases: [Purchase] = skProducts.map { skProduct in
            let price = Price(from: skProduct.price, in: skProduct.priceLocale)
            
            return Purchase(productIdentifier: skProduct.productIdentifier, price: price, skProduct: skProduct)
        }
        
        print(purchases)
        
        self.onCompletion(.succeeded(Set(purchases)))
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        self.onCompletion(.failed(error))
    }
}
