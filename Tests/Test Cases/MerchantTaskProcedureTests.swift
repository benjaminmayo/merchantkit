import XCTest
@testable import MerchantKit

class MerchantTaskProcedureTests : XCTestCase {
    func testSuccessfulFetchPurchaseAndPurchaseProduct() {
        let product = Product(identifier: "testProduct", kind: .nonConsumable)
        let skProduct = MockSKProduct(productIdentifier: "testProduct", price: NSDecimalNumber(string: "0.99"), priceLocale: Locale(identifier: "en_US_POSIX"))

        let availablePurchases = PurchaseSet(from: [Purchase(from: .availableProduct(skProduct), for: product)])
    
        self.runTest(with: [product],
                     availablePurchasesResult: .success(availablePurchases),
                     commitPurchaseResult: ("testProduct", .success))
    }
}

extension MerchantTaskProcedureTests {
    private func runTest(with products: Set<Product>, availablePurchasesResult: Result<PurchaseSet, Error>, commitPurchaseResult: (productIdentifier: String, result: Result<Void, Error>)) {
        let completionExpectation = self.expectation(description: "Async expectation")
        completionExpectation.expectedFulfillmentCount = products.count
        
        let mockDelegate = MockMerchantDelegate()
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.availablePurchasesResult = availablePurchasesResult
        mockStoreInterface.commitPurchaseResult = commitPurchaseResult
        mockStoreInterface.receiptFetchResult = .success(Data())
        
        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
        merchant.register(products)
        merchant.setup()
        
        let task = merchant.availablePurchasesTask(for: products)
        task.onCompletion = { result in
            do {
                let purchases = try result.get()
                
                for product in products {
                    guard let purchase = purchases.purchase(for: product) else {
                        XCTFail("`Purchase` not found for \(product)")
                        
                        return
                    }
                    
                    let task = merchant.commitPurchaseTask(for: purchase)
                    task.onCompletion = { result in
                        switch result {
                            case .success(_):
                                XCTAssertTrue(merchant.state(for: product).isPurchased, "The product \(product) should be purchased after a successful commit.")
                            
                            case .failure(_):
                                XCTFail("Failed to commit purchase.")
                        }
                        
                        completionExpectation.fulfill()
                    }
                    
                    task.start()
                }
            } catch {
                completionExpectation.fulfill()
            }
        }
        
        task.start()
        
        self.wait(for: [completionExpectation], timeout: 10)
    }
}
