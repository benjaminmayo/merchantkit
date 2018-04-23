import XCTest
import Foundation
@testable import MerchantKit

class MerchantTests : XCTestCase {
    private var didAttemptReceiptValidationExpectation: XCTestExpectation?
    
    func testInitialization() {
        let testStorage = EphemeralPurchaseStorage()
        
        let merchant = Merchant(storage: testStorage, delegate: self)
        XCTAssertFalse(merchant.isLoading)
    }
    
    func testProductRegistration() {
        let testStorage = EphemeralPurchaseStorage()
        let testProduct = Product(identifier: "testProduct", kind: .nonConsumable)
        
        let merchant = Merchant(storage: testStorage, delegate: self)
        merchant.register([testProduct])
        
        let foundProduct = merchant.product(withIdentifier: "testProduct")
        XCTAssertNotNil(foundProduct)
        XCTAssertEqual(foundProduct, testProduct)
    }
    
    func testNonConsumableProductPurchasedStateWithReceiptValidation() {
        let testStorage = EphemeralPurchaseStorage()
        let testProduct = Product(identifier: "testNonConsumableProduct", kind: .nonConsumable)
        
        let merchant = Merchant(storage: testStorage, delegate: self)
        merchant.setCustomReceiptDataFetcherInitializer({ [unowned self] policy in
            let testingFetcher = TestingReceiptDataFetcher(policy: policy)
            testingFetcher.result = self.testingSucceededResultData
            return testingFetcher
        })
        merchant.register([testProduct])
        merchant.setup()
        
        let expectation = self.expectation(description: "wait for `merchant(_:, validate: completion) to be called")
        self.didAttemptReceiptValidationExpectation = expectation
        
        self.wait(for: [expectation], timeout: 5)
        
        let state = merchant.state(for: testProduct)
        XCTAssertTrue(state.isPurchased)
    }
    
    func testSubscriptionProductPurchasedStateWithReceiptValidation() {
        let testStorage = EphemeralPurchaseStorage()
        let testProduct = Product(identifier: "testSubscriptionProduct", kind: .subscription(automaticallyRenews: true))
        
        let merchant = Merchant(storage: testStorage, delegate: self)
        merchant.setCustomReceiptDataFetcherInitializer({ [unowned self] policy in
            let testingFetcher = TestingReceiptDataFetcher(policy: policy)
            testingFetcher.result = self.testingSucceededResultData
            return testingFetcher
        })
        merchant.register([testProduct])
        merchant.setup()
        
        let expectation = self.expectation(description: "wait for `merchant(_:, validate: completion) to be called")
        self.didAttemptReceiptValidationExpectation = expectation
        
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
    
    private var testingSucceededResultData: Result<Data> {
        return .succeeded(Data())
    }
}

extension MerchantTests : MerchantDelegate {
    func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>) {
        
    }
    
    func merchant(_ merchant: Merchant, validate request: ReceiptValidationRequest, completion: @escaping (Result<Receipt>) -> Void) {
        let nonConsumableEntry = ReceiptEntry(productIdentifier: "testNonConsumableProduct", expiryDate: nil)
        let subscriptionEntry1 = ReceiptEntry(productIdentifier: "testSubscriptionProduct", expiryDate: Date(timeIntervalSinceNow: -60 * 5))
        let subscriptionEntry2 = ReceiptEntry(productIdentifier: "testSubscriptionProduct", expiryDate: Date(timeIntervalSinceNow: 60))
        let subscriptionEntry3 = ReceiptEntry(productIdentifier: "testSubscriptionProduct", expiryDate: Date(timeIntervalSinceNow: 60 * 60 * 24))

        let receipt = ConstructedReceipt(from: [nonConsumableEntry, subscriptionEntry1, subscriptionEntry2, subscriptionEntry3])
        
        completion(.succeeded(receipt))
        
        self.didAttemptReceiptValidationExpectation?.fulfill()
    }
}

private class TestingReceiptDataFetcher : ReceiptDataFetcher {
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
