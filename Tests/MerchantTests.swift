import XCTest
import Foundation
@testable import MerchantKit

class MerchantTests : XCTestCase {
    func testInitialization() {
        let mockDelegate = MockValidationMerchantDelegate()
        
        let testStorage = EphemeralPurchaseStorage()
        
        let merchant = Merchant(storage: testStorage, delegate: mockDelegate)
        XCTAssertFalse(merchant.isLoading)
    }
    
    func testProductRegistration() {
        let mockDelegate = MockValidationMerchantDelegate()
        
        let testStorage = EphemeralPurchaseStorage()
        let testProduct = Product(identifier: "testProduct", kind: .nonConsumable)
        
        let merchant = Merchant(storage: testStorage, delegate: mockDelegate)
        merchant.register([testProduct])
        
        let foundProduct = merchant.product(withIdentifier: "testProduct")
        XCTAssertNotNil(foundProduct)
        XCTAssertEqual(foundProduct, testProduct)
    }
    
    func testNonConsumableProductPurchasedStateWithMockedReceiptValidation() {
        let testStorage = EphemeralPurchaseStorage()
        let testProduct = Product(identifier: "testNonConsumableProduct", kind: .nonConsumable)

        let expectation = self.expectation(description: "wait for `merchant(_:, validate: completion) to be called")

        let mockDelegate = MockValidationMerchantDelegate()
        mockDelegate.validateRequest = { request, completion in
            let nonConsumableEntry = ReceiptEntry(productIdentifier: "testNonConsumableProduct", expiryDate: nil)
            
            let receipt = ConstructedReceipt(from: [nonConsumableEntry])
            
            completion(.succeeded(receipt))
            
            expectation.fulfill()
        }
        
        let merchant = Merchant(storage: testStorage, delegate: mockDelegate)
        merchant.setCustomReceiptDataFetcherInitializer({ policy in
            let testingFetcher = MockReceiptDataFetcher(policy: policy)
            testingFetcher.result = .succeeded(Data())
            
            return testingFetcher
        })
        merchant.register([testProduct])
        merchant.setup()
        
        self.wait(for: [expectation], timeout: 5)
        
        let state = merchant.state(for: testProduct)
        XCTAssertTrue(state.isPurchased)
    }
    
    func testSubscriptionProductPurchasedStateWithMockedReceiptValidation() {
        let testStorage = EphemeralPurchaseStorage()
        let testProduct = Product(identifier: "testSubscriptionProduct", kind: .subscription(automaticallyRenews: true))
        
        let expectation = self.expectation(description: "wait for `merchant(_:, validate: completion) to be called")

        let mockDelegate = MockValidationMerchantDelegate()
        mockDelegate.validateRequest = { request, completion in
            let subscriptionEntry1 = ReceiptEntry(productIdentifier: "testSubscriptionProduct", expiryDate: Date(timeIntervalSinceNow: -60 * 5))
            let subscriptionEntry2 = ReceiptEntry(productIdentifier: "testSubscriptionProduct", expiryDate: Date(timeIntervalSinceNow: 60))
            let subscriptionEntry3 = ReceiptEntry(productIdentifier: "testSubscriptionProduct", expiryDate: Date(timeIntervalSinceNow: 60 * 60 * 24))
            
            let receipt = ConstructedReceipt(from: [subscriptionEntry1, subscriptionEntry2, subscriptionEntry3])
            
            completion(.succeeded(receipt))
            
            expectation.fulfill()
        }
        
        let merchant = Merchant(storage: testStorage, delegate: mockDelegate)
        merchant.setCustomReceiptDataFetcherInitializer({ policy in
            let testingFetcher = MockReceiptDataFetcher(policy: policy)
            testingFetcher.result = .succeeded(Data())
            
            return testingFetcher
        })
        merchant.register([testProduct])
        merchant.setup()
        
        self.wait(for: [expectation], timeout: 5)
        
        let state = merchant.state(for: testProduct)
        XCTAssertTrue(state.isPurchased)
        
        switch state {
            case .isPurchased(let info):
                let expiryDate = info.expiryDate
                XCTAssertNotNil(expiryDate)
                
                XCTAssertGreaterThan(expiryDate!, Date(timeIntervalSinceNow: 60 * 2))
            default:
                XCTFail("incorrect state, should be `isPurchased`")
        }
    }
    
    func testConsumableProductWithLocalReceiptValidation() {
        guard let receiptData = self.dataForSampleResource(withName: "testSampleReceiptTwoNonConsumablesPurchased", extension: "data") else {
            XCTFail("sample resource not found")
            return
        }
        
        let testStorage = EphemeralPurchaseStorage()
        let testProductIdentifiers = ["codeSharingUnlockable", "saveScannedCodeUnlockable"]
        let testProducts: [Product] = testProductIdentifiers.map {
            Product(identifier: $0, kind: .nonConsumable)
        }
        
        let expectations: [XCTestExpectation] = testProductIdentifiers.map { productIdentifier in
            self.expectation(description: "\(productIdentifier) didChangeState to purchased")
        }
        
        var merchant: Merchant!
        
        let mockDelegate = MockValidationMerchantDelegate()
        mockDelegate.validateRequest = { (request, completion) in
            let validator = LocalReceiptValidator(request: request)
            validator.onCompletion = { result in
                completion(result)
            }
            
            validator.start()
        }
        mockDelegate.didChangeStates = { products in
            for product in products {
                if merchant.state(for: product).isPurchased {
                    guard let index = testProductIdentifiers.index(of: product.identifier) else {
                        XCTFail("unexpected product \(product.identifier) surfaced by Merchant")
                        continue
                    }
                    
                    expectations[index].fulfill()
                }
            }
        }
        
        merchant = Merchant(storage: testStorage, delegate: mockDelegate)
        merchant.setCustomReceiptDataFetcherInitializer({ policy in
            let testingFetcher = MockReceiptDataFetcher(policy: policy)
            testingFetcher.result = .succeeded(receiptData)
            
            return testingFetcher
        })
        
        merchant.register(testProducts)
        merchant.setup()
        
        self.waitForExpectations(timeout: 5, handler: { error in
            guard error == nil else { return }
            
            // sanity check every test product one more time
            
            for testProduct in testProducts {
                let state = merchant.state(for: testProduct)
                XCTAssertTrue(state.isPurchased)
            }
        })
    }
}

private class MockValidationMerchantDelegate : MerchantDelegate {
    var validateRequest: ((_ request: ReceiptValidationRequest, _ completion: @escaping (Result<Receipt>) -> Void) -> Void)!
    var didChangeStates: ((_ products: Set<Product>) -> Void)?
    
    init() {
        
    }
    
    func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>) {
        self.didChangeStates?(products)
    }
    
    func merchant(_ merchant: Merchant, validate request: ReceiptValidationRequest, completion: @escaping (Result<Receipt>) -> Void) {
        self.validateRequest(request, completion)
    }
}

private class MockReceiptDataFetcher : ReceiptDataFetcher {
    private var completionBlocks = [Completion]()
    
    typealias Completion = (Result<Data>) -> Void
    
    var result: Result<Data>!
    
    required init(policy: ReceiptFetchPolicy) {
        
    }
    
    func enqueueCompletion(_ completion: @escaping Completion) {
        self.completionBlocks.append(completion)
    }
    
    func start() {
        for block in self.completionBlocks {
            block(self.result)
        }
    }
    
    func cancel() {
        
    }
}
