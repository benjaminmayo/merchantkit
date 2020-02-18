import XCTest
@testable import MerchantKit

class MerchantTaskProcedureTests : XCTestCase {
    func testSuccessfulFetchPurchaseAndPurchaseProduct() {
        let productsAndPurchases = self.testProductsAndPurchases()
        
        let commitPurchaseResults: [String : Result<Void, Error>] = Dictionary(uniqueKeysWithValues: productsAndPurchases.map { ($0.0.identifier, .success) })
        let availablePurchases = PurchaseSet(from: productsAndPurchases.map { $0.1 })
    
        let outcomes = productsAndPurchases.map { $0.0 }.map {
            ProductExpectedOutcome(
                for: $0,
                finalState: $0.kind == .consumable ? .notPurchased : .isPurchased(PurchasedProductInfo(expiryDate: nil)),
                isPurchaseExists: true,
                isSuccessfulCommit: true)
        }
        
        self.runTest(
            with: outcomes,
            availablePurchasesResult: .success(availablePurchases),
            commitPurchaseResults: commitPurchaseResults
        )
    }
    
    func testFailureToFetch() {
        let productsAndPurchases = self.testProductsAndPurchases()
        let outcomes = productsAndPurchases.map { $0.product }.map { ProductExpectedOutcome(for: $0, finalState: .notPurchased, isPurchaseExists: false, isSuccessfulCommit: false) }

		self.runTest(with: outcomes, availablePurchasesResult: .failure(.other(MockError.mockError)), commitPurchaseResults: [:])
    }
    
    func testCancelledFetch() {
        let completionExpectation = self.expectation(description: "Cancelled fetch.")
        completionExpectation.isInverted = true
        
        let testProductsAndPurchases = self.testProductsAndPurchases()
        let products = testProductsAndPurchases.map { $0.product }

        let mockDelegate = MockMerchantDelegate()
        
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.receiptFetchResult = .failure(MockError.mockError)
        mockStoreInterface.availablePurchasesResult = .success(PurchaseSet(from: testProductsAndPurchases.map { $0.purchase }))
        
        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
        merchant.register(products)
        merchant.setup()
        
        let task = merchant.availablePurchasesTask(for: Set(products))
        task.onCompletion = { _ in
            completionExpectation.fulfill()
        }
        
        task.start()
        task.cancel()
        
        self.wait(for: [completionExpectation], timeout: 3)
    }
    
    func testSuccessfulFetchAndFailureToPurchase() {
        let productsAndPurchases = self.testProductsAndPurchases()
        
        let commitPurchaseResults: [String : Result<Void, Error>] = Dictionary(uniqueKeysWithValues: productsAndPurchases.map { ($0.0.identifier, .failure(MockError.mockError)) })
        let availablePurchases = PurchaseSet(from: productsAndPurchases.map { $0.1 })
        
        let outcomes = productsAndPurchases.map { $0.0 }.map { ProductExpectedOutcome(for: $0, finalState: .notPurchased, isPurchaseExists: true, isSuccessfulCommit: false) }
        
        self.runTest(
            with: outcomes,
            availablePurchasesResult: .success(availablePurchases),
            commitPurchaseResults: commitPurchaseResults
        )
    }
    
    func testRestorePurchases() {
        let allProducts = self.testProductsAndPurchases().map { $0.0 }
        let productsWithoutSubscriptions = allProducts.filter { $0.kind == .nonConsumable || $0.kind == .consumable }
        
        let randomOtherProduct = Product(identifier: "randomOtherProductIdentifier", kind: .nonConsumable)
        
        for products in [allProducts, productsWithoutSubscriptions] {
            let completionExpectation = self.expectation(description: "Completed restoring purchases.")

            let mockDelegate = MockMerchantDelegate()
            let mockStoreInterface = MockStoreInterface()
            mockStoreInterface.receiptFetchResult = .success(Data())
            mockStoreInterface.restoredProductsResult = Result<Set<String>, Error>.success(Set(products.map { $0.identifier }))
            
            let validator = MockReceiptValidator()
            validator.validateRequest = { request, completion in
                let metadata = ReceiptMetadata(originalApplicationVersion: "1.0")

                guard request.reason == .restorePurchases else {
                    completion(.success(ConstructedReceipt(from: [], metadata: metadata)))
                    
                    return
                }
                
                let entries = products.map { product in
                    ReceiptEntry(productIdentifier: product.identifier, expiryDate: nil)
                }
                
                let receipt = ConstructedReceipt(from: entries, metadata: metadata)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                    completion(.success(receipt))
                })
            }
            
            let configuration = Merchant.Configuration(receiptValidator: validator, storage: EphemeralPurchaseStorage())
            
            let merchant = Merchant(configuration: configuration, delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
            merchant.canGenerateLogs = true

            merchant.register(products + [randomOtherProduct])
            merchant.setup()
            
            let task = merchant.restorePurchasesTask()
            task.onCompletion = { result in
                for product in products {
                    if product.kind != .consumable {
                        XCTAssertTrue(merchant.state(for: product).isPurchased, "Product \(product) was expected to be purchased after restoration, but the state reported it was not purchased.")
                    }
                }
                
                completionExpectation.fulfill()
            }
            
            task.start()
            
            mockStoreInterface.dispatchCommitPurchaseEvent(forProductWith: randomOtherProduct.identifier, result: .failure(MockError.mockError), afterDelay: 0)
            
            self.wait(for: [completionExpectation], timeout: 5)
        }
    }
    
    func testReceiptMetadataResultsMatchExpectations() {
        guard let dataForReceipt = self.dataForSampleResource(withName: "testSampleReceiptTwoNonConsumablesPurchased", extension: "data") else {
            XCTFail("sample resource not found")
            
            return
        }
        
        let resultsAndExpectations: [(Result<Data, Error>, Result<ReceiptMetadata, Error>)] = [
            (.failure(MockError.mockError), .failure(MockError.mockError)),
            (.success(Data()), .failure(ASN1.Parser.Error.emptyData)),
            (.success(dataForReceipt), .success(ReceiptMetadata(originalApplicationVersion: "26", bundleIdentifier: "com.anthonymayo.qrcodes", creationDate: Date(timeIntervalSince1970: 1523813798.0))))
        ]
        
        func evaluate(_ result: Result<ReceiptMetadata, Error>, withExpectation expectedResult: Result<ReceiptMetadata, Error>) {
            switch (result, expectedResult) {
                case (.success(let metadata), .success(let expectedMetadata)) where metadata == expectedMetadata:
                    break
                case (.success(let metadata), .success(let expectedMetadata)):
                    XCTFail("The task succeeded with metadata \(metadata) when a success was expected with metadata \(expectedMetadata).")
                case (.success(let metadata), .failure(let expectedError)):
                    XCTFail("The task succeeded with metadata \(metadata) when a failure was expected with error \(expectedError).")
                case (.failure(MockError.mockError), .failure(MockError.mockError)):
                    break
                case (.failure(ASN1.Parser.Error.emptyData), .failure(ASN1.Parser.Error.emptyData)):
                    break
                case (.failure(let error), .success(let expectedMetadata)):
                    XCTFail("The task failed with error \(error) when a success with metadata \(expectedMetadata) was expected.")
                case (.failure(let error), .failure(let expectedError)):
                    XCTFail("The task failed with error \(error), when \(expectedError) was expected.")
            }
        }
        
        let completionExpectation = self.expectation(description: "Completed fetching receipt metadata.")
        completionExpectation.expectedFulfillmentCount = resultsAndExpectations.count
        
        var index = 0
        
        func runNextResult() {
            guard index < resultsAndExpectations.endIndex else { return }

            let (result, expectedResult) = resultsAndExpectations[index]

            index += 1

            let mockDelegate = MockMerchantDelegate()
            let mockStoreInterface = MockStoreInterface()
            mockStoreInterface.receiptFetchResult = result
            
            let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
            merchant.canGenerateLogs = true
            
            merchant.register([])
            merchant.setup()
            
            let task = merchant.receiptMetadataTask()
            task.onCompletion = { result in
                evaluate(result, withExpectation: expectedResult)
                
                let repeatedTask = merchant.receiptMetadataTask()
                repeatedTask.onCompletion = { repeatedResult in
                    evaluate(result, withExpectation: repeatedResult)
                    
                    completionExpectation.fulfill()
                    
                    runNextResult()
                }
                
                repeatedTask.start()
            }
            
            task.start()
        }
        
        runNextResult()
        
        self.wait(for: [completionExpectation], timeout: 5)
    }
    
    func testReceiptMetadataUsesLatestReceipt() {
        let testProduct = Product(identifier: "testProduct", kind: .nonConsumable)
        
        let mockDelegate = MockMerchantDelegate()
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.receiptFetchResult = .success(Data())

        let mockReceipt = ConstructedReceipt(from: [ReceiptEntry(productIdentifier: testProduct.identifier, expiryDate: nil)], metadata: ReceiptMetadata(originalApplicationVersion: ""))

        let mockReceiptValidator = MockReceiptValidator()
        mockReceiptValidator.validateRequest = { (request, completion) in
            completion(.success(mockReceipt))
        }
        
        let configuration = Merchant.Configuration(receiptValidator: mockReceiptValidator, storage: EphemeralPurchaseStorage())
        let merchant = Merchant(configuration: configuration, delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
        merchant.canGenerateLogs = true
        
        merchant.register([testProduct])
        merchant.setup()
        
        let latestFetchedReceiptExpectation = self.expectation(description: "Found a latest fetched receipt.")
        
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true, block: { timer in
            if let receipt = merchant.latestFetchedReceipt {
                timer.invalidate()
                
                XCTAssertEqual(receipt.productIdentifiers, mockReceipt.productIdentifiers)
                
                latestFetchedReceiptExpectation.fulfill()
            }
        })
        
        self.wait(for: [latestFetchedReceiptExpectation], timeout: 5)
        
        mockStoreInterface.receiptFetchResult = .failure(MockError.mockError)
        
        let completionExpectation = self.expectation(description: "Fetched receipt metadata.")

        let task = merchant.receiptMetadataTask()
        task.onCompletion = { result in
            switch result {
                case .success(let metadata):
                    XCTAssertEqual(metadata, mockReceipt.metadata)
                case .failure(let error):
                    XCTFail("The task failed with \(error) when success was expected with receipt \(mockReceipt.metadata).")
            }
            
            completionExpectation.fulfill()
        }
        
        task.start()
        
        self.wait(for: [completionExpectation], timeout: 5)
    }
    
    public func testAvailablePurchasesDefaultsToAllProductsIfNoProductsSpecified() {
        let testProducts = Set(self.testProductsAndPurchases().map { $0.product })
        
        let mockDelegate = MockMerchantDelegate()
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.receiptFetchResult = .success(Data())
        
        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
        merchant.canGenerateLogs = true
        
        merchant.register(testProducts)
        merchant.setup()
        
        let task = merchant.availablePurchasesTask() // create task without specifying any products
        
        XCTAssertEqual(task.products, testProducts)
    }
}

extension MerchantTaskProcedureTests {
    struct ProductExpectedOutcome {
        let product: Product
        let finalState: PurchasedState
        let isPurchaseExists: Bool
        let isSuccessfulCommit: Bool
        
        init(for product: Product, finalState: PurchasedState, isPurchaseExists: Bool, isSuccessfulCommit: Bool) {
            self.product = product
            self.finalState = finalState
            self.isPurchaseExists = isPurchaseExists
            self.isSuccessfulCommit = isSuccessfulCommit
        }
    }
    
    private func runTest(with expectedOutcomes: [ProductExpectedOutcome], availablePurchasesResult: Result<PurchaseSet, AvailablePurchasesFetcherError>, commitPurchaseResults: [String : Result<Void, Error>]) {
        let products = Set(expectedOutcomes.map { $0.product })
        XCTAssertEqual(products.count, expectedOutcomes.count)
        
        let completionExpectation = self.expectation(description: "Completed determining outcomes for products under test.")
        completionExpectation.expectedFulfillmentCount = expectedOutcomes.count
        let changeLoadingStateExpectation = self.expectation(description: "did change loading state expectation")
        changeLoadingStateExpectation.assertForOverFulfill = false
        
        let consumedExpectation: XCTestExpectation? = {
            let expectedConsumedCount = expectedOutcomes.count(where: {
                $0.product.kind == .consumable && $0.isSuccessfulCommit
            })
            
            guard expectedConsumedCount > 0 else { return nil }
            
            let expectation = self.expectation(description: "Consumed expectation.")
            expectation.expectedFulfillmentCount = expectedConsumedCount
            
            return expectation
        }()
        
        var merchant: Merchant!
        let mockDelegate = MockMerchantDelegate()
        mockDelegate.didChangeLoadingState = {
            if !merchant.isLoading {
                changeLoadingStateExpectation.fulfill()
            }
        }
        
        let mockConsumableProductsHandler = MockMerchantConsumableProductHandler()
        mockConsumableProductsHandler.consumeProduct = { product, completion in
            consumedExpectation?.fulfill()
            
            completion()
        }
        
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.availablePurchasesResult = availablePurchasesResult
        mockStoreInterface.receiptFetchResult = .success(Data())
        
        merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: mockConsumableProductsHandler, storeInterface: mockStoreInterface)
        merchant.canGenerateLogs = true
        
        merchant.register(products)
        merchant.setup()
        
        let task = merchant.availablePurchasesTask(for: products)
        task.onCompletion = { result in
            do {
                let purchases = try result.get()
                
                if case .failure(let error) = availablePurchasesResult {
                    XCTFail("Succeeded to fetch purchases \(purchases) when failure, with error \(error), was expected")
                }
                
                for outcome in expectedOutcomes {
                    let product = outcome.product
                    
                    guard let purchase = purchases.purchase(for: product) else {
                        XCTFail("`Purchase` not found for \(product)")
                        
                        return
                    }
                    
                    let task = merchant.commitPurchaseTask(for: purchase)
                    task.onCompletion = { result in
                        switch result {
                            case .success(_):
                                if !outcome.isSuccessfulCommit {
                                    XCTFail("Committed purchase for product \(product) when it was expected to fail.")
                                }
                            case .failure(_):
                                if outcome.isSuccessfulCommit {
                                    XCTFail("Failed to commit purchase for product \(product) when it was expected to succeed.")
                                }
                        }
                        
                        XCTAssertEqual(outcome.finalState, merchant.state(for: outcome.product), "The product \(outcome.product) was expected to have final state \(outcome.finalState) but the `Merchant` reported \(merchant.state(for: outcome.product)).")

                        completionExpectation.fulfill()
                    }
                    
                    task.start()
                    
                    if let commitPurchaseResult = commitPurchaseResults[outcome.product.identifier] {
                        mockStoreInterface.dispatchCommitPurchaseEvent(forProductWith: outcome.product.identifier, result: commitPurchaseResult, afterDelay: .random(in: 0.1...0.5))
                    }
                }
            } catch let error {
                switch availablePurchasesResult {
                    case .success(_):
                        XCTFail("Failed to fetch purchases when success was expected.")
                    case .failure(let expectedError):// where let expectedError = expectedError as AvailablePurchasesError:
                        if let foundError = error as? AvailablePurchasesFetcherError {
							switch (foundError, expectedError) {
								case (.userNotAllowedToMakePurchases, .userNotAllowedToMakePurchases): break
								case (.noAvailablePurchases(let a), .noAvailablePurchases(let b)) where a == b: break
								case (.other(let a as NSError), .other(let b as NSError)) where a == b: break
								default:
									XCTFail("Failed to fetch purchases with error \(foundError), when error \(expectedError) was expected.")
							}
                        } else {
                            XCTFail("Failed to fetch purchases with error \(error), when error \(expectedError) was expected.")
                        }
                }
            
                for outcome in expectedOutcomes {
                    XCTAssertEqual(outcome.finalState, merchant.state(for: outcome.product), "The product \(outcome.product) was expected to have final state \(outcome.finalState) but the `Merchant` reported \(merchant.state(for: outcome.product)).")
                    
                    completionExpectation.fulfill()
                }
            }
        }
        
        task.start()
        
        self.wait(for: [consumedExpectation, completionExpectation, changeLoadingStateExpectation].compactMap { $0 }, timeout: 5, enforceOrder: true)
    }
    
    private func testProductsAndPurchases(forKinds kinds: [Product.Kind] = [.consumable, .nonConsumable, .subscription(automaticallyRenews: false), .subscription(automaticallyRenews: true)]) -> [(product: Product, purchase: Purchase)] {
        return kinds.enumerated().map { i, kind in
            let identifier = "testProduct\(i)"
            
            let product = Product(identifier: identifier, kind: kind)
            let skProduct = MockSKProduct(productIdentifier: identifier, price: NSDecimalNumber(string: "0.99"), priceLocale: Locale(identifier: "en_US_POSIX"))
            let purchase = Purchase(from: .availableProduct(skProduct), for: product)
            
            return (product: product, purchase: purchase)
        }
    }
}
