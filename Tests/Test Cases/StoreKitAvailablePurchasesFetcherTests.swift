import XCTest
@testable import MerchantKit

class StoreKitAvailablePurchasesFetcherTests : XCTestCase {
    func testSimulateAvailablePurchasesFetcherSuccess() {
        let testProduct = Product(identifier: "testProduct", kind: .nonConsumable)
        
        let completionExpectation = self.expectation(description: "Completed simulated available purchases fetch.")
        
        let mockSKProduct = MockSKProduct(productIdentifier: testProduct.identifier, price: NSDecimalNumber(string: "1.99"), priceLocale: Locale(identifier: "en_US_POSIX"))
        
        let fetcher = StoreKitAvailablePurchasesFetcher(forProducts: [testProduct])
        fetcher.enqueueCompletion({ result in
            let purchase = Purchase(from: .availableProduct(mockSKProduct), for: testProduct)
            let expectedPurchases = PurchaseSet(from: [purchase])
            
            switch result {
                case .success(let purchases) where purchases == expectedPurchases:
                    break
                case .success(let purchases):
                    XCTFail("The fetcher succeeded with purchases \(purchases) when it was expected to succeed with purchases \(expectedPurchases).")
                case .failure(let error):
                    XCTFail("The fetcher failed with error \(error) when it was expected to succeed.")
            }
            
            completionExpectation.fulfill()
        })
        
        fetcher.start()
        
        let mockRequest = SKProductsRequest(productIdentifiers: [])
        class MockSKProductsResponse : SKProductsResponse {
            private let _products: [SKProduct]
            
            init(products: [SKProduct]) {
                self._products = products
                
                super.init()
            }
            
            override var products: [SKProduct] {
                return self._products
            }
        }
        
        let mockProductsResponse = MockSKProductsResponse(products: [mockSKProduct])
        
        fetcher.productsRequest(mockRequest, didReceive: mockProductsResponse)
        
        self.wait(for: [completionExpectation], timeout: 5)
    }
}


