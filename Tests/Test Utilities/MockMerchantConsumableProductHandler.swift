import MerchantKit

final class MockMerchantConsumableProductHandler : MerchantConsumableProductHandler {
    var consumeProduct: ((_ product: Product, _ completion: @escaping () -> Void) -> Void)!
    
    func merchant(_ merchant: Merchant, consume product: Product, completion: @escaping () -> Void) {
        return self.consumeProduct!(product, completion)
    }
}
