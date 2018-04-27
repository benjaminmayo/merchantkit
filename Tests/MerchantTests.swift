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
        let testProduct = Product(identifier: "testNonConsumableProduct", kind: .nonConsumable)
        let expectedOutcome = ProductTestExpectedOutcome(for: testProduct, finalState: .isPurchased(PurchasedProductInfo(expiryDate: nil)))
        
        self.runTest(with: [expectedOutcome], withReceiptDataFetchResult: .succeeded(Data()), validationRequestHandler: { (request, completion) in
            let nonConsumableEntry = ReceiptEntry(productIdentifier: "testNonConsumableProduct", expiryDate: nil)
            
            let receipt = ConstructedReceipt(from: [nonConsumableEntry])
            
            completion(.succeeded(receipt))
        })
    }
    
    func testSubscriptionProductPurchasedStateWithMockedReceiptValidation() {
        let firstExpiryDate = Date(timeIntervalSinceNow: -60 * 5)
        let secondExpiryDate = Date(timeIntervalSinceNow: 60)
        let thirdExpiryDate = Date(timeIntervalSinceNow: 60 * 60 * 24)
        
        let testProduct = Product(identifier: "testSubscriptionProduct", kind: .subscription(automaticallyRenews: true))
        let expectedOutcome = ProductTestExpectedOutcome(for: testProduct, finalState: .isPurchased(PurchasedProductInfo(expiryDate: thirdExpiryDate)))
        
        self.runTest(with: [expectedOutcome], withReceiptDataFetchResult: .succeeded(Data()), validationRequestHandler: { (request, completion) in
            let subscriptionEntry1 = ReceiptEntry(productIdentifier: "testSubscriptionProduct", expiryDate: firstExpiryDate)
            let subscriptionEntry2 = ReceiptEntry(productIdentifier: "testSubscriptionProduct", expiryDate: secondExpiryDate)
            let subscriptionEntry3 = ReceiptEntry(productIdentifier: "testSubscriptionProduct", expiryDate: thirdExpiryDate)
            
            let receipt = ConstructedReceipt(from: [subscriptionEntry1, subscriptionEntry2, subscriptionEntry3])
            
            completion(.succeeded(receipt))
        })
    }
    
    func testConsumableProductWithLocalReceiptValidation() {
        guard let receiptData = self.dataForSampleResource(withName: "testSampleReceiptTwoNonConsumablesPurchased", extension: "data") else {
            XCTFail("sample resource not found")
            return
        }
        
        let testProducts: Set<Product> = [
            Product(identifier: "codeSharingUnlockable", kind: .nonConsumable),
            Product(identifier: "saveScannedCodeUnlockable", kind: .nonConsumable)
        ]
        let expectedOutcome = testProducts.map { product in
            ProductTestExpectedOutcome(for: product, finalState: .isPurchased(PurchasedProductInfo(expiryDate: nil)))
        }
        
        self.runTest(with: expectedOutcome, withReceiptDataFetchResult: .succeeded(receiptData), validationRequestHandler: { (request, completion) in
            let validator = LocalReceiptValidator(request: request)
            validator.onCompletion = { result in
                completion(result)
            }
            
            validator.start()
        })
    }
    
    func testFailureWithServerReceiptValidationFailure() {
        guard let receiptData = self.dataForSampleResource(withName: "testSampleReceiptTwoNonConsumablesPurchased", extension: "data") else {
            XCTFail("sample resource not found")
            return
        }
        
        let testProducts: Set<Product> = [
            Product(identifier: "codeSharingUnlockable", kind: .nonConsumable),
            Product(identifier: "saveScannedCodeUnlockable", kind: .nonConsumable)
        ]
        let expectedOutcomes = testProducts.map { product in
            ProductTestExpectedOutcome(for: product, finalState: .notPurchased, shouldChangeState: false)
        }
        
        self.runTest(with: expectedOutcomes, withReceiptDataFetchResult: .succeeded(receiptData), validationRequestHandler: { (request, completion) in
            let validator = ServerReceiptValidator(request: request, sharedSecret: "thisisnotarealsharedsecret")
            validator.onCompletion = { result in
                completion(result)
            }
            
            validator.start()
        })
    }
}

extension MerchantTests {
    fileprivate typealias ValidationRequestHandler = ((_ request: ReceiptValidationRequest, _ completion: @escaping (Result<Receipt>) -> Void) -> Void)
    
    struct ProductTestExpectedOutcome {
        let product: Product
        let finalState: PurchasedState
        let shouldChangeState: Bool
        
        init(for product: Product, finalState: PurchasedState, shouldChangeState: Bool = true) {
            self.product = product
            self.finalState = finalState
            self.shouldChangeState = shouldChangeState
        }
    }
    
    fileprivate func runTest(with outcomes: [ProductTestExpectedOutcome], withReceiptDataFetchResult receiptDataFetchResult: Result<Data>, validationRequestHandler: @escaping ValidationRequestHandler) {
        let testStorage = EphemeralPurchaseStorage()
        
        let testExpectations: [XCTestExpectation] = outcomes.map { outcome in
            let testExpectation = self.expectation(description: "\(outcome.product) didChangeState to expected state")
            testExpectation.isInverted = !outcome.shouldChangeState
            
            return testExpectation
        }
        
        var merchant: Merchant!
        
        let mockDelegate = MockValidationMerchantDelegate()
        mockDelegate.validateRequest = validationRequestHandler
        
        mockDelegate.didChangeStates = { products in
            for product in products {
                guard let index = outcomes.index(where: { $0.product == product }) else {
                    XCTFail("unexpected product \(product.identifier) surfaced by Merchant")
                    continue
                }
                
                let expectedFinalState = outcomes[index].finalState
                
                if merchant.state(for: product) == expectedFinalState {
                    testExpectations[index].fulfill()
                }
            }
        }
        
        merchant = Merchant(storage: testStorage, delegate: mockDelegate)
        merchant.setCustomReceiptDataFetcherInitializer({ policy in
            let testingFetcher = MockReceiptDataFetcher(policy: policy)
            testingFetcher.result = receiptDataFetchResult
            
            return testingFetcher
        })
        
        merchant.register(outcomes.map { $0.product })
        merchant.setup()
        
        self.waitForExpectations(timeout: 5, handler: { error in
            guard error == nil else { return }
            
            // sanity check every test product one more time
            
            for expectation in outcomes {
                let foundState = merchant.state(for: expectation.product)
                
                XCTAssertEqual(expectation.finalState, foundState)
            }
        })
    }
}

private class MockValidationMerchantDelegate : MerchantDelegate {
    var validateRequest: MerchantTests.ValidationRequestHandler!
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
