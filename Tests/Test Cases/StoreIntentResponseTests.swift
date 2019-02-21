import XCTest
@testable import MerchantKit

class StoreIntentResponseTests : XCTestCase {
    func testShouldDeferUnknownProducts() {
        let mockMerchantDelegate = MockMerchantDelegate()
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.receiptFetchResult = .failure(MockError.mockError)
        
        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockMerchantDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
        merchant.canGenerateLogs = true

        merchant.register([])
        merchant.setup()
        
        let skProduct = MockSKProduct(productIdentifier: "", price: NSDecimalNumber(string: "1.00"), priceLocale: .init(identifier: "en_US_POSIX"))
        let skPayment = MockSKPayment()
        
        let source = Purchase.Source.pendingStorePayment(skProduct, skPayment)
        
        let response = mockStoreInterface.dispatchStoreIntentToCommitPurchase(from: source)
        
        XCTAssertEqual(response, .defer)
    }
    
    func testShouldRespectDelegateForKnownProducts() {
        class CustomMockMerchantDelegate : MerchantDelegate {
            var storeIntentResponse: StoreIntentResponse = .default
            
            func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>) {
                
            }
            
            func merchant(_ merchant: Merchant, didReceiveStoreIntentToCommit purchase: Purchase) -> StoreIntentResponse {
                return self.storeIntentResponse
            }
        }
        
        let mockMerchantDelegate = CustomMockMerchantDelegate()

        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.receiptFetchResult = .failure(MockError.mockError)
        
        let testProduct = Product(identifier: "testProduct", kind: .nonConsumable)
        
        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockMerchantDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
        merchant.canGenerateLogs = true

        merchant.register([testProduct])
        merchant.setup()
        
        let skProduct = MockSKProduct(productIdentifier: testProduct.identifier, price: NSDecimalNumber(string: "1.00"), priceLocale: .init(identifier: "en_US_POSIX"))
        let skPayment = MockSKPayment()
        
        let source = Purchase.Source.pendingStorePayment(skProduct, skPayment)
        
        let possibleResponses: [StoreIntentResponse] = [.automaticallyCommit, .defer]
        
        for response in possibleResponses {
            mockMerchantDelegate.storeIntentResponse = response
            
            let receivedResponse = mockStoreInterface.dispatchStoreIntentToCommitPurchase(from: source)
        
            XCTAssertEqual(receivedResponse, response)
        }
    }
}
