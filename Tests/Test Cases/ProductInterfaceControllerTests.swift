import XCTest
@testable import MerchantKit

class ProductInterfaceControllerTests : XCTestCase {
    func testCommitPurchase() {
        let testProductsAndPurchases = self.testProductsAndPurchases()
        let testProducts = testProductsAndPurchases.map { $0.product }
        
        let completionExpectation = self.expectation(description: "Commit purchase finished.")
        completionExpectation.expectedFulfillmentCount = testProducts.count
        
        let mockDelegate = MockMerchantDelegate()
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.availablePurchasesResult = .success(PurchaseSet(from: testProductsAndPurchases.map { $0.purchase }))
        mockStoreInterface.receiptFetchResult = .success(Data())
        
        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
        merchant.register(testProducts)
        merchant.setup()
        
        let delegate = MockProductInterfaceControllerDelegate()
        
        let controller = ProductInterfaceController(products: Set(testProducts), with: merchant)
        controller.delegate = delegate
        
        delegate.didChangeStates = { products in
            guard products == Set(testProducts) else { return }
            
            switch controller.fetchingState {
                case .dormant:
                    for (product, purchase) in testProductsAndPurchases {
                        let state = controller.state(for: product)
                        
                        switch state {
                            case .purchasable(let foundPurchase):
                                XCTAssertEqual(foundPurchase, purchase, "The controller reported a `Purchase` but it did not match what was supplied by the `StoreInterface`.")
                                
                                controller.commit(foundPurchase)
                            
                                mockStoreInterface.dispatchCommitPurchaseEvent(forProductWith: product.identifier, result: .success)
                            case let state:
                                XCTFail("The controller reported state \(state) for product \(product), but `purchasable` was expected.")
                        }
                    }
                default:
                    break
            }
        }
        
        delegate.didCommit = { (product, result) in
            switch result {
                case .success(_):
                    break
                case .failure(let error):
                    XCTFail("The commit purchase failed with \(error) when it was expected to succeed.")
            }
            
            completionExpectation.fulfill()
        }
        
        controller.fetchDataIfNecessary()

        self.wait(for: [completionExpectation], timeout: 5)
    }
    
    func testRefetch() {
        let testProductsAndPurchases = self.testProductsAndPurchases()
        let testProducts = testProductsAndPurchases.map { $0.product }
        
        let completionExpectation = self.expectation(description: "Refetch finished.")
        
        let mockDelegate = MockMerchantDelegate()
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.availablePurchasesResult = .failure(MockError.mockError)
        mockStoreInterface.receiptFetchResult = .success(Data())
        
        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
        merchant.register(testProducts)
        merchant.setup()
        
        self.mockProductInterfaceControllerDelegate = MockProductInterfaceControllerDelegate()
        
        let controller = ProductInterfaceController(products: Set(testProducts), with: merchant)
        controller.delegate = self.mockProductInterfaceControllerDelegate
        
        self.mockProductInterfaceControllerDelegate.didChangeFetchingState = {
            switch controller.fetchingState {
                case .failed(.genericProblem):
                    mockStoreInterface.availablePurchasesResult = .success(PurchaseSet(from: testProductsAndPurchases.map { $0.purchase }))
                    
                    self.mockProductInterfaceControllerDelegate.didChangeFetchingState = {                        
                        switch controller.fetchingState {
                            case .dormant:
                                for (product, purchase) in testProductsAndPurchases {
                                    let state = controller.state(for: product)
                                    
                                    switch state {
                                        case .purchasable(let foundPurchase):
                                            XCTAssertEqual(foundPurchase, purchase, "The controller reported a `Purchase` but it did not match what was supplied by the `StoreInterface`.")
                                            
                                            controller.commit(foundPurchase)
                                            
                                            mockStoreInterface.dispatchCommitPurchaseEvent(forProductWith: product.identifier, result: .success)
                                        case let state:
                                            XCTFail("The controller reported state \(state) for product \(product), but `purchasable` was expected.")
                                    }
                                }
                                
                                completionExpectation.fulfill()
                            default:
                                break
                        }
                       
                    }
                    
                    controller.fetchDataIfNecessary()
                case .failed(let reason):
                    XCTFail("The fetching state failed with \(reason) when \(ProductInterfaceController.FetchingState.FailureReason.genericProblem) was expected.")
                default:
                    break
            }
        }
        
        controller.fetchDataIfNecessary()
        
        self.wait(for: [completionExpectation], timeout: 10)
    }
    
    private var mockProductInterfaceControllerDelegate: MockProductInterfaceControllerDelegate!
}

extension ProductInterfaceControllerTests {
    private func testProductsAndPurchases(forKinds kinds: [Product.Kind] = [.nonConsumable, .subscription(automaticallyRenews: false), .subscription(automaticallyRenews: true)]) -> [(product: Product, purchase: Purchase)] {
        return kinds.enumerated().map { i, kind in
            let identifier = "testProduct\(i)"
            
            let product = Product(identifier: identifier, kind: kind)
            let skProduct = MockSKProduct(productIdentifier: identifier, price: NSDecimalNumber(string: "0.99"), priceLocale: Locale(identifier: "en_US_POSIX"))
            let purchase = Purchase(from: .availableProduct(skProduct), for: product)
            
            return (product, purchase)
        }
    }
}

fileprivate class MockProductInterfaceControllerDelegate : ProductInterfaceControllerDelegate {
    var didChangeFetchingState: (() -> Void)?
    var didChangeStates: ((Set<Product>) -> Void)?
    var didCommit: ((Purchase, ProductInterfaceController.CommitPurchaseResult) -> Void)?
    var didRestore: ((ProductInterfaceController.RestorePurchasesResult) -> Void)?
    
    func productInterfaceControllerDidChangeFetchingState(_ controller: ProductInterfaceController) {
        self.didChangeFetchingState?()
    }
    
    func productInterfaceController(_ controller: ProductInterfaceController, didChangeStatesFor products: Set<Product>) {
        self.didChangeStates?(products)
    }
    
    func productInterfaceController(_ controller: ProductInterfaceController, didCommit purchase: Purchase, with result: ProductInterfaceController.CommitPurchaseResult) {
        self.didCommit?(purchase, result)
    }
    
    func productInterfaceController(_ controller: ProductInterfaceController, didRestorePurchasesWith result: ProductInterfaceController.RestorePurchasesResult) {
        self.didRestore?(result)
    }
}
