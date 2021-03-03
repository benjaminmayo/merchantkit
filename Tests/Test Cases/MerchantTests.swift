import XCTest
import Foundation
@testable import MerchantKit

class MerchantTests : XCTestCase {
    private let metadata = ReceiptMetadata(originalApplicationVersion: "1.0")
    
    func testInitialization() {
        let mockDelegate = MockMerchantDelegate()
        let mockStoreInterface = MockStoreInterface()

        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
        merchant.canGenerateLogs = true

        XCTAssertFalse(merchant.isLoading)
    }
    
    func testSetupAndSetupAgainIsNoop() {
        let validateExpectation = self.expectation(description: "Validated once.")
        validateExpectation.expectedFulfillmentCount = 1
        validateExpectation.assertForOverFulfill = true
        
        let testProduct = Product(identifier: "testProduct", kind: .nonConsumable)
        let storage = EphemeralPurchaseStorage()
        
        let mockReceiptValidator = MockReceiptValidator()
        mockReceiptValidator.validateRequest = { request, completion in
            validateExpectation.fulfill()
            
            completion(.failure(MockError.mockError))
        }
        
        let mockDelegate = MockMerchantDelegate()
        
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.receiptFetchResult = .success(Data())
        
        let merchant = Merchant(configuration: Merchant.Configuration(receiptValidator: mockReceiptValidator, storage: storage), delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
        merchant.canGenerateLogs = true
        merchant.register([testProduct])
        
        merchant.setup()
        merchant.setup()
        
        self.wait(for: [validateExpectation], timeout: 3)
    }
    
    func testProductRegistration() {
        let mockDelegate = MockMerchantDelegate()
        let mockStoreInterface = MockStoreInterface()
        
        let testProduct = Product(identifier: "testProduct", kind: .nonConsumable)
        
        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
        merchant.canGenerateLogs = true

        merchant.register([testProduct])
        
        let foundProduct = merchant.product(withIdentifier: "testProduct")
        XCTAssertNotNil(foundProduct)
        XCTAssertEqual(foundProduct, testProduct)
    }
    
    func testNonConsumableProductPurchasedStateWithMockedReceiptValidation() {
        let testProduct = Product(identifier: "testNonConsumableProduct", kind: .nonConsumable)
        let expectedOutcome = ProductTestExpectedOutcome(for: testProduct, finalState: .isPurchased(PurchasedProductInfo(expiryDate: nil)))
        
        self.runTest(with: [expectedOutcome], withReceiptDataFetchResult: .success(Data()), validationRequestHandler: { (request, completion) in
            let nonConsumableEntry = ReceiptEntry(productIdentifier: "testNonConsumableProduct", expiryDate: nil)
            
            let receipt = ConstructedReceipt(from: [nonConsumableEntry], metadata: self.metadata)
            
            completion(.success(receipt))
        })
    }
    
    func testSubscriptionProductPurchasedStateWithMockedReceiptValidation() {
        let firstExpiryDate = Date(timeIntervalSinceNow: -60 * 5)
        let secondExpiryDate = Date(timeIntervalSinceNow: 60)
        let thirdExpiryDate = Date(timeIntervalSinceNow: 60 * 60 * 24)
        
        let testProduct = Product(identifier: "testSubscriptionProduct", kind: .subscription(automaticallyRenews: true))
        let expectedOutcome = ProductTestExpectedOutcome(for: testProduct, finalState: .isPurchased(PurchasedProductInfo(expiryDate: thirdExpiryDate)))
        
        self.runTest(with: [expectedOutcome], withReceiptDataFetchResult: .success(Data()), validationRequestHandler: { (request, completion) in
            let subscriptionEntry1 = ReceiptEntry(productIdentifier: "testSubscriptionProduct", expiryDate: firstExpiryDate)
            let subscriptionEntry2 = ReceiptEntry(productIdentifier: "testSubscriptionProduct", expiryDate: secondExpiryDate)
            let subscriptionEntry3 = ReceiptEntry(productIdentifier: "testSubscriptionProduct", expiryDate: thirdExpiryDate)
            
            let receipt = ConstructedReceipt(from: [subscriptionEntry1, subscriptionEntry2, subscriptionEntry3], metadata: self.metadata)
            
            completion(.success(receipt))
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
        
        self.runTest(with: expectedOutcome, withReceiptDataFetchResult: .success(receiptData), validationRequestHandler: { (request, completion) in
            let validator = LocalReceiptValidator()
            
            validator.validate(request, completion: { result in
                completion(result)
            })
        })
    }
    
    func testConsumableProductWithServerReceiptValidation() throws {
        try XCTSkipIf({ return true }(), "todo: fix later")
        
        guard let receiptData = self.dataForSampleResource(withName: "testSampleReceiptTwoNonConsumablesPurchased", extension: "data") else {
            XCTFail("sample resource not found")
            return
        }
        
        let testProducts: Set<Product> = [
            Product(identifier: "codeSharingUnlockable", kind: .nonConsumable),
            Product(identifier: "saveScannedCodeUnlockable", kind: .nonConsumable)
        ]
        let expectedOutcomes = testProducts.map { product in
            ProductTestExpectedOutcome(for: product, finalState: .isPurchased(PurchasedProductInfo(expiryDate: nil)))
        }
        
        self.runTest(with: expectedOutcomes, withReceiptDataFetchResult: .success(receiptData), validationRequestHandler: { (request, completion) in
            let validator = ServerReceiptValidator(sharedSecret: nil)
            validator.validate(request, completion: { result in
                completion(result)
            })
        })
    }
    
    func testSubscriptionProductWithFailingServerReceiptValidation() {
        guard let receiptData = self.dataForSampleResource(withName: "testSampleReceiptOneSubscriptionPurchased", extension: "data") else {
            XCTFail("sample resource not found")
            return
        }
        
        let product = Product(identifier: "premiumsubscription", kind: .subscription(automaticallyRenews: true))
        
        let expectedOutcome = ProductTestExpectedOutcome(for: product, finalState: .notPurchased, shouldChangeState: false)
        
        self.runTest(with: [expectedOutcome], withReceiptDataFetchResult: .success(receiptData), validationRequestHandler: { (request, completion) in
            let validator = ServerReceiptValidator(sharedSecret: nil)
            validator.validate(request, completion: { result in
                completion(result)
            })
        })
    }
    
    func testIgnoresStoreInterfaceMessagesForUnregisteredProducts() {
        let somethingChangedExpectation = self.expectation(description: "Some event triggered.")
        somethingChangedExpectation.isInverted = true
        
        let mockDelegate = MockMerchantDelegate()
        mockDelegate.didChangeStates = { _ in
            somethingChangedExpectation.fulfill()
        }
        
        let mockConsumableProductHandler = MockMerchantConsumableProductHandler()
        mockConsumableProductHandler.consumeProduct = { (_, completion) in
            somethingChangedExpectation.fulfill()
            
            completion()
        }
        
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.receiptFetchResult = .success(Data())
        mockStoreInterface.restoredProductsResult = .success(Set(["unrelatedProduct"]))
        
        let testProduct = Product(identifier: "testProduct", kind: .nonConsumable)
        
        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
        merchant.canGenerateLogs = true
        merchant.register([testProduct])
        merchant.setup()
        
        mockStoreInterface.dispatchCommitPurchaseEvent(forProductWith: "unrelatedProduct", result: .success, afterDelay: 0.1)
        mockStoreInterface.dispatchCommitPurchaseEvent(forProductWith: "unrelatedProduct2", result: .success, afterDelay: 0.1)
        mockStoreInterface.dispatchCommitPurchaseEvent(forProductWith: "unrelatedProduct", result: .failure(MockError.mockError), afterDelay: 0.1)
        mockStoreInterface.restorePurchases(using: merchant.storeParameters)
        
        self.wait(for: [somethingChangedExpectation], timeout: 5)
    }
    
    func testRestoreSubscriptionPurchaseSubscriptionWithFailingReceiptValidation() {
        let completionExpectation = self.expectation(description: "Completed restore purchases.")
        
        let testProduct = Product(identifier: "testProduct", kind: .subscription(automaticallyRenews: true))
        
        let mockDelegate = MockMerchantDelegate()
        
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.receiptFetchResult = .failure(MockError.mockError)
        mockStoreInterface.restoredProductsResult = .success(Set([testProduct.identifier]))
        
        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
        merchant.canGenerateLogs = true
        merchant.register([testProduct])
        merchant.setup()

        let task = merchant.restorePurchasesTask()
        task.onCompletion = { _ in
            completionExpectation.fulfill()
        }
        
        task.start()
        
        self.wait(for: [completionExpectation], timeout: 4)
    }
    
    func testConsumeProductFailsIfConsumableHandlerUnset() {
        let testProduct = Product(identifier: "testProduct", kind: .consumable)
        
        let mockDelegate = MockMerchantDelegate()
        
        let expectation = self.expectation(description: "Fatal error thrown.")
        
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.receiptFetchResult = .success(Data())
        mockStoreInterface.restoredProductsResult = .success(Set(["unrelatedProduct"]))
        
        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
        merchant.canGenerateLogs = true
        merchant.register([testProduct])
        merchant.setup()
     
        MerchantKitFatalError.customHandler = {
            expectation.fulfill()
        }
        
        let mockSKProduct = MockSKProduct(productIdentifier: testProduct.identifier, price: NSDecimalNumber(string: "0.99"), priceLocale: Locale(identifier: "en_US_POSIX"))
        let purchase = Purchase(from: .availableProduct(mockSKProduct), for: testProduct)
        
        let task = merchant.commitPurchaseTask(for: purchase)
        task.start()
        
        mockStoreInterface.dispatchCommitPurchaseEvent(forProductWith: testProduct.identifier, result: .success, afterDelay: 0.1, on: DispatchQueue.global(qos: .background))
        
        self.wait(for: [expectation], timeout: 3)
        
        MerchantKitFatalError.customHandler = nil
    }
    
    func testSubscriptionExpiredUponInitialization() {
        let testProduct = Product(identifier: "testProduct", kind: .subscription(automaticallyRenews: true))
        
        let pastDate = Date(timeIntervalSinceNow: -60 * 60 * 24 * 7)
        let outdatedRecord = PurchaseRecord(productIdentifier: testProduct.identifier, expiryDate: pastDate)
        
        let storage = EphemeralPurchaseStorage()
        _ = storage.save(outdatedRecord)
        
        var merchant: Merchant!
        
        let expectation = self.expectation(description: "Subscription expired.")

        let mockValidator = MockReceiptValidator()
        mockValidator.subscriptionRenewalLeeway = .init(allowedElapsedDuration: 0)
        mockValidator.validateRequest = { request, completion in
            let entry = ReceiptEntry(productIdentifier: testProduct.identifier, expiryDate: pastDate)
            
            let receipt = ConstructedReceipt(from: [entry], metadata: ReceiptMetadata(originalApplicationVersion: ""))
            
            completion(.success(receipt))
        }
        
        let mockDelegate = MockMerchantDelegate()
        mockDelegate.didChangeStates = { products in            
            guard products.contains(testProduct) else { return }
            
            let state = merchant.state(for: testProduct)
            XCTAssertFalse(state.isPurchased, "The subscription state reported state \(state) when it was expected to be \(PurchasedState.notPurchased) as subscription expired in the past.")
            
            expectation.fulfill()
        }
        
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.receiptFetchResult = .success(Data())
        
        merchant = Merchant(configuration: Merchant.Configuration(receiptValidator: mockValidator, storage: storage), delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
        merchant.canGenerateLogs = true
        merchant.register([testProduct])
        merchant.setup()
        
        self.wait(for: [expectation], timeout: 5)
    }
    
    func testProductRemovedFromReceipt() {
        let completionExpectation = self.expectation(description: "Completed validate request.")
        
        let testProduct = Product(identifier: "testProduct", kind: .nonConsumable)
        
        let record = PurchaseRecord(productIdentifier: testProduct.identifier, expiryDate: nil)
        
        let storage = EphemeralPurchaseStorage()
        _ = storage.save(record)
        
        var merchant: Merchant!
        
        let mockValidator = MockReceiptValidator()
        mockValidator.validateRequest = { request, completion in
            let receipt = ConstructedReceipt(from: [], metadata: ReceiptMetadata(originalApplicationVersion: ""))
            
            completion(.success(receipt))
        }
        
        let mockDelegate = MockMerchantDelegate()
        mockDelegate.didChangeStates = { products in
            XCTAssertFalse(merchant.state(for: testProduct).isPurchased)
            
            completionExpectation.fulfill()
        }
        
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.receiptFetchResult = .success(Data())
        
        merchant = Merchant(configuration: Merchant.Configuration(receiptValidator: mockValidator, storage: storage), delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
        merchant.canGenerateLogs = true
        merchant.register([testProduct])
        merchant.setup()
        
        self.wait(for: [completionExpectation], timeout: 5)
    }
    
    func testMerchantLoggerActivatedDeactivated() {
        let mockDelegate = MockMerchantDelegate()

        let mockStoreInterface = MockStoreInterface()

        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
        XCTAssertFalse(merchant.canGenerateLogs)
        
        merchant.canGenerateLogs = true
        XCTAssertTrue(merchant.canGenerateLogs)
        
        merchant.canGenerateLogs = false
        XCTAssertFalse(merchant.canGenerateLogs)
    }
    
    func testReuseReceiptFetcher() {
        let completionExpectation = self.expectation(description: "Completed commit.")
        let receiptFetchCompleteExpectation = self.expectation(description: "Fetched from receipt.")
        receiptFetchCompleteExpectation.assertForOverFulfill = true
        
        let testProduct = Product(identifier: "testProduct", kind: .subscription(automaticallyRenews: true))
        
        let mockSKProduct = MockSKProduct(productIdentifier: testProduct.identifier, price: NSDecimalNumber(string: "1.99"), priceLocale: Locale(identifier: "en_US_POSIX"))
        let purchase = Purchase(from: .availableProduct(mockSKProduct), for: testProduct)
        
        let storage = EphemeralPurchaseStorage()
        
        let mockReceiptValidator = MockReceiptValidator()
        mockReceiptValidator.validateRequest = { request, completion in
            let entry = ReceiptEntry(productIdentifier: testProduct.identifier, expiryDate: Date(timeIntervalSinceNow: 60 * 60 * 24 * 7))
            
            let receipt = ConstructedReceipt(from: [entry], metadata: ReceiptMetadata(originalApplicationVersion: ""))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                completion(.success(receipt))
            })
        }
        
        let mockDelegate = MockMerchantDelegate()
        
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.receiptFetchResult = .success(Data())
        mockStoreInterface.receiptFetchDelay = 3
        mockStoreInterface.receiptFetchDidComplete = {
            receiptFetchCompleteExpectation.fulfill()
        }
        
        mockStoreInterface.availablePurchasesResult = .success(PurchaseSet(from: [purchase]))
        
        let merchant = Merchant(configuration: Merchant.Configuration(receiptValidator: mockReceiptValidator, storage: storage), delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
        merchant.canGenerateLogs = true
        merchant.register([testProduct])
        merchant.setup()
        
        let task = merchant.availablePurchasesTask(for: [testProduct])
        task.onCompletion = { result in
            switch result {
                case .success(let purchases):
                    guard let purchase = purchases.purchase(for: testProduct) else {
                        XCTFail("The available purchases task succeeded but did not provide a product for the \(testProduct).")
                        
                        return
                    }
                    
                    let task = merchant.commitPurchaseTask(for: purchase)
                    task.onCompletion = { result in
                        completionExpectation.fulfill()
                    }
                    
                    task.start()
                    mockStoreInterface.dispatchCommitPurchaseEvent(forProductWith: testProduct.identifier, result: .success)
                case .failure(let error):
                    XCTFail("The available purchases task failed with error \(error) when it was expected to succeed.")
            }
        }
        
        task.start()
        
        self.wait(for: [receiptFetchCompleteExpectation, completionExpectation], timeout: 10)
    }
    
    func testEnsureSetupMessageLogged() {
        let mockDelegate = MockMerchantDelegate()
        let mockStoreInterface = MockStoreInterface()

        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
        _ = merchant.availablePurchasesTask()
    }
}

extension MerchantTests {
    fileprivate typealias ValidationRequestHandler = ((_ request: ReceiptValidationRequest, _ completion: @escaping (Result<Receipt, Error>) -> Void) -> Void)
    
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
    
    fileprivate func runTest(with outcomes: [ProductTestExpectedOutcome], withReceiptDataFetchResult receiptDataFetchResult: Result<Data, Error>, validationRequestHandler: @escaping ValidationRequestHandler) {
        let testExpectations: [XCTestExpectation] = outcomes.map { outcome in
            let testExpectation = self.expectation(description: "\(outcome.product) didChangeState to expected state")
            testExpectation.isInverted = !outcome.shouldChangeState
            
            return testExpectation
        }
        
        var merchant: Merchant!
        
        let validateRequestCompletionExpectation = self.expectation(description: "validation request completion handler called")
        
        let mockReceiptValidator = MockReceiptValidator()
        mockReceiptValidator.validateRequest = { request, completion in
            let interceptedCompletion: (Result<Receipt, Error>) -> Void = { result in
                validateRequestCompletionExpectation.fulfill()
                
                completion(result)
            }
            
            validationRequestHandler(request, interceptedCompletion)
        }
        
        let mockDelegate = MockMerchantDelegate()
        mockDelegate.didChangeStates = { products in
            for product in products {
                guard let index = outcomes.firstIndex(where: { $0.product == product }) else {
                    XCTFail("unexpected product \(product.identifier) surfaced by Merchant")
                    continue
                }
                
                let expectedFinalState = outcomes[index].finalState
                
                if merchant.state(for: product) == expectedFinalState {
                    testExpectations[index].fulfill()
                }
            }
        }
        
        let configuration = Merchant.Configuration(receiptValidator: mockReceiptValidator, storage: EphemeralPurchaseStorage())
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.receiptFetchResult = receiptDataFetchResult
            
        merchant = Merchant(configuration: configuration, delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
        merchant.canGenerateLogs = true
        
        merchant.register(outcomes.map { $0.product })
        merchant.setup()
        
        self.wait(for: [validateRequestCompletionExpectation] + testExpectations, timeout: 5)
        
        // sanity check every test product one more time
            
        for expectation in outcomes {
            let foundState = merchant.state(for: expectation.product)
                
            XCTAssertEqual(expectation.finalState, foundState)
        }
    }
}
