import XCTest
import StoreKit
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
        
        let mockConsumableProductsHandler = MockMerchantConsumableProductHandler()
        mockConsumableProductsHandler.consumeProduct = { product, completion in
            completion()
        }
        
        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: mockConsumableProductsHandler, storeInterface: mockStoreInterface)
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
                            default:
                                XCTFail("The controller reported state \(state) for product \(product), but `purchasable` was expected.")
                        }
                    }
                default:
                    break
            }
        }
        
        delegate.didCommit = { (purchase, result) in
            switch result {
                case .success(_):
                    let product = controller.products.first(where: { $0.identifier ==  purchase.productIdentifier })!
                    let state = controller.state(for: product)
                
                    switch state {
                        case .purchased(_, let metadata):
                            if #available(iOS 11.2, *) {
                                if case .subscription(automaticallyRenews: _) = product.kind {
                                    XCTAssertNotNil(metadata?.subscriptionTerms, "Subscription products should have associated subscription terms.")
                                } else {
                                    XCTAssertNil(metadata?.subscriptionTerms, "Non-subscription products should not have associated subscription terms.")
                                }
                            }
                        default:
                            if product.kind != .consumable {
                                XCTFail("The commit purchase succeeded but the state was not correctly updated to `purchased`.")
                            }
                    }
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
		mockStoreInterface.availablePurchasesResult = .failure(.other(MockError.mockError))
        mockStoreInterface.receiptFetchResult = .success(Data())
        
        let mockConsumableProductsHandler = MockMerchantConsumableProductHandler()
        mockConsumableProductsHandler.consumeProduct = { product, completion in
            completion()
        }
        
        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: mockConsumableProductsHandler, storeInterface: mockStoreInterface)
        merchant.register(testProducts)
        merchant.setup()
        
        let mockProductInterfaceControllerDelegate = MockProductInterfaceControllerDelegate()
        
        let controller = ProductInterfaceController(products: Set(testProducts), with: merchant)
        controller.delegate = mockProductInterfaceControllerDelegate
        
        mockProductInterfaceControllerDelegate.didChangeFetchingState = {
            switch controller.fetchingState {
				case .failed(.genericProblem(MockError.mockError)):
                    mockStoreInterface.availablePurchasesResult = .success(PurchaseSet(from: testProductsAndPurchases.map { $0.purchase }))
                    
                    mockProductInterfaceControllerDelegate.didChangeFetchingState = {
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
                    XCTFail("The fetching state failed with \(reason) when \(ProductInterfaceController.FetchingState.FailureReason.genericProblem(MockError.mockError)) was expected.")
                default:
                    break
            }
        }
        
        controller.fetchDataIfNecessary()
        
        self.wait(for: [completionExpectation], timeout: 10)
    }
    
    
    func testUnknownProduct() {
        let testProducts = self.testProductsAndPurchases().map { $0.product }
        
        let mockDelegate = MockMerchantDelegate()
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.receiptFetchResult = .success(Data())
        
        let mockConsumableProductsHandler = MockMerchantConsumableProductHandler()
        mockConsumableProductsHandler.consumeProduct = { product, completion in
            completion()
        }
        
        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: mockConsumableProductsHandler, storeInterface: mockStoreInterface)
        merchant.register(testProducts)
        merchant.setup()
            
        let controller = ProductInterfaceController(products: Set(testProducts), with: merchant)
            
        let nonExistentProduct = Product(identifier: "nonExistentProduct", kind: .nonConsumable)
            
        let state = controller.state(for: nonExistentProduct)
        
        XCTAssertEqual(state, .unknown)
    }
    
    func testCommitPurchaseErrorMatchesExpectations() {
        let testProductsAndPurchases = self.testProductsAndPurchases()
        let testProducts = testProductsAndPurchases.map { $0.product }
        
        let mockDelegate = MockMerchantDelegate()
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.receiptFetchResult = .success(Data())
        mockStoreInterface.availablePurchasesResult = .success(PurchaseSet(from: testProductsAndPurchases.map { $0.purchase }))
        
        let mockConsumableProductsHandler = MockMerchantConsumableProductHandler()
        mockConsumableProductsHandler.consumeProduct = { product, completion in
            completion()
        }
        
        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: mockConsumableProductsHandler, storeInterface: mockStoreInterface)
        merchant.register(testProducts)
        merchant.setup()
        
        let mockProductInterfaceControllerDelegate = MockProductInterfaceControllerDelegate()
        
        let controller = ProductInterfaceController(products: Set(testProducts), with: merchant)
        controller.delegate = mockProductInterfaceControllerDelegate
        
        let (commitProduct, commitPurchase) = testProductsAndPurchases.first!
        
        let errorsAndExpectations: [(Error, ProductInterfaceController.CommitPurchaseError)] = {
            var errorsAndExpectations: [(Error, ProductInterfaceController.CommitPurchaseError)] = [
                (SKError(.paymentCancelled), .userCancelled),
                (SKError(.paymentNotAllowed), .paymentNotAllowed),
                (SKError(.paymentInvalid), .paymentInvalid),
                (URLError(.notConnectedToInternet), .networkError(URLError(.notConnectedToInternet))),
                (MockError.mockError, .genericProblem(MockError.mockError))
            ]
            
            #if os(iOS)
            errorsAndExpectations.append((SKError(.storeProductNotAvailable), .purchaseNotAvailable))
            #endif
            
            return errorsAndExpectations
        }()
        
        var index = 0
        
        let completionExpectation = self.expectation(description: "Commit purchase failed")
        completionExpectation.expectedFulfillmentCount = errorsAndExpectations.count
        
        func isCommitPurchaseErrorEquivalent(_ error: ProductInterfaceController.CommitPurchaseError, otherError: ProductInterfaceController.CommitPurchaseError) -> Bool {
            switch (error, otherError) {
                case (.userCancelled, .userCancelled): return true
                case (.networkError(let a), .networkError(let b)): return a.code == b.code
                case (.purchaseNotAvailable, .purchaseNotAvailable): return true
                case (.paymentNotAllowed, .paymentNotAllowed): return true
                case (.paymentInvalid, .paymentInvalid): return true
                case (.genericProblem(let a as MockError), .genericProblem(let b as MockError)): return a == b
                default: return false
            }
        }
        
        func runNextMockFailure() {
            guard index < errorsAndExpectations.endIndex else { return }

            let (error, expectedError) = errorsAndExpectations[index]
            
            index += 1
            
            mockProductInterfaceControllerDelegate.didCommit = { (purchase, result) in
                XCTAssertEqual(commitPurchase, purchase)
                
                switch result {
                    case .success(_):
                        break
                    case .failure(let error):
                        XCTAssertTrue(isCommitPurchaseErrorEquivalent(error, otherError: expectedError))
                }
                
                completionExpectation.fulfill()
                
                runNextMockFailure()
            }
            
            controller.commit(commitPurchase)
            mockStoreInterface.dispatchCommitPurchaseEvent(forProductWith: commitProduct.identifier, result: .failure(error), afterDelay: 0.2)
        }
        
        runNextMockFailure()
        
        self.wait(for: [completionExpectation], timeout: 10)
    }
    
    func testFetchPurchaseErrorMatchesExpectations() {
        let skError: SKError
        
        #if os(iOS)
        skError = SKError(.storeProductNotAvailable)
        #elseif os(macOS)
        skError = SKError(.paymentNotAllowed)
        #endif
        
        let errors: [Error] = [
            URLError(.notConnectedToInternet),
            skError,
            MockError.mockError
        ]
        
        func isFetchingErrorEquivalent(_ error: Error, to fetchReason: ProductInterfaceController.FetchingState.FailureReason) -> Bool {
            switch (error, fetchReason) {
                case (let a as URLError, .networkFailure(let b)): return a.code == b.code
                case (let a as SKError, .storeKitFailure(let b)): return a.code == b.code
                case (MockError.mockError, .genericProblem): return true
                default: return false
            }
        }
        
        var index = 0
        
        let completionExpectation = self.expectation(description: "Commit purchase failed")
        completionExpectation.expectedFulfillmentCount = errors.count
        
        func runNextMockFailure() {
            guard index < errors.endIndex else { return }
            
            let error = errors[index]
            
            index += 1
            
            let testProductsAndPurchases = self.testProductsAndPurchases()
            let testProducts = testProductsAndPurchases.map { $0.product }
            
            let mockDelegate = MockMerchantDelegate()
            let mockStoreInterface = MockStoreInterface()
            mockStoreInterface.receiptFetchResult = .success(Data())
			mockStoreInterface.availablePurchasesResult = .failure(.other(error))

            let mockConsumableProductsHandler = MockMerchantConsumableProductHandler()
            mockConsumableProductsHandler.consumeProduct = { product, completion in
                completion()
            }
            
            let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: mockConsumableProductsHandler, storeInterface: mockStoreInterface)
            merchant.register(testProducts)
            merchant.setup()
            
            let mockProductInterfaceControllerDelegate = MockProductInterfaceControllerDelegate()
            self.productInterfaceControllerDelegate = mockProductInterfaceControllerDelegate
            
            let controller = ProductInterfaceController(products: Set(testProducts), with: merchant)
            controller.delegate = mockProductInterfaceControllerDelegate
            
            self.productInterfaceController = controller
            
            mockProductInterfaceControllerDelegate.didChangeFetchingState = {
                switch controller.fetchingState {
                    case .failed(let fetchReason):
                        XCTAssertTrue(isFetchingErrorEquivalent(error, to: fetchReason))
                        
                        completionExpectation.fulfill()
                        
                        runNextMockFailure()
                    default:
                        break
                }
                
            }
            
            controller.fetchDataIfNecessary()
        }
        
        runNextMockFailure()
        
        self.wait(for: [completionExpectation], timeout: 10)
    }
    
    func testCommitPurchaseErrorShouldDisplayInUserInterface() {
        let allErrors: [ProductInterfaceController.CommitPurchaseError] = [
           .genericProblem(MockError.mockError),
           .networkError(URLError(.badURL)),
           .paymentInvalid,
           .paymentNotAllowed,
           .purchaseNotAvailable,
           .userCancelled
        ]
        
        for error in allErrors {
            switch error {
                case .userCancelled:
                    XCTAssertFalse(error.shouldDisplayInUserInterface)
                default:
                    XCTAssertTrue(error.shouldDisplayInUserInterface)
            }
        }
    }
    
    func testCommitPurchaseNotRegisteredWithProductInterfaceController() {
        let testProducts = self.testProductsAndPurchases().map { $0.product }

        let mockDelegate = MockMerchantDelegate()
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.receiptFetchResult = .success(Data())
        
        let mockConsumableProductsHandler = MockMerchantConsumableProductHandler()
        mockConsumableProductsHandler.consumeProduct = { product, completion in
            completion()
        }

        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: mockConsumableProductsHandler, storeInterface: mockStoreInterface)
        merchant.register(testProducts)
        merchant.setup()
        
        let controller = ProductInterfaceController(products: Set(testProducts), with: merchant)
        
        let otherProduct = Product(identifier: "otherProduct", kind: .nonConsumable)
        let otherProductPurchase = Purchase(from: .availableProduct(MockSKProduct(productIdentifier: otherProduct.identifier, price: NSDecimalNumber(string: "1.99"), priceLocale: Locale(identifier: "en_US_POSIX"))), for: otherProduct)
        
        let expectation = self.expectation(description: "Fatal error thrown.")
        
        MerchantKitFatalError.customHandler = {
            expectation.fulfill()
        }
        
        let testingQueue = DispatchQueue(label: "testing queue") // testing MerchantKitFatalError requires dispatch to a non-main thread

        testingQueue.async {
            controller.commit(otherProductPurchase)
        }
        
        self.wait(for: [expectation], timeout: 5)
    }
    
    func testRestorePurchases() {
        let testProducts = self.testProductsAndPurchases().map { $0.product }
        
        let expectedResults: [Result<Set<Product>, Error>] = [
            .failure(MockError.mockError),
            .success(Set(testProducts))
        ]
        
        let completionExpectation = self.expectation(description: "Completed restore purchases.")
        completionExpectation.expectedFulfillmentCount = expectedResults.count
        
        var index = 0
        
        func runNextResult() {
            guard index < expectedResults.endIndex else { return }
            let expectedResult = expectedResults[index]
            
            index += 1
            
            let mockDelegate = MockMerchantDelegate()
            
            let mockStoreInterface = MockStoreInterface()
            mockStoreInterface.receiptFetchResult = .success(Data())
            mockStoreInterface.restoredProductsResult = expectedResult.map { products in
                Set(products.map { $0.identifier })
            }
            
            let mockReceiptValidator = MockReceiptValidator()
            mockReceiptValidator.validateRequest = { request, completion in
                let metadata = ReceiptMetadata(originalApplicationVersion: "")
                
                guard request.reason == .restorePurchases else {
                    completion(.success(ConstructedReceipt(from: [], metadata: metadata)))
                    
                    return
                }
                
                let entries: [ReceiptEntry] = testProducts.compactMap { product in
                    switch product.kind {
                        case .subscription(automaticallyRenews: _):
                            return ReceiptEntry(productIdentifier: product.identifier, expiryDate: Date(timeIntervalSinceNow: 60 * 60 * 24 * 7))
                        case .nonConsumable:
                            return ReceiptEntry(productIdentifier: product.identifier, expiryDate: nil)
                        default:
                            return nil
                    }
                }
                
                let receipt = ConstructedReceipt(from: entries, metadata: metadata)
                
                completion(.success(receipt))
            }
            
            let mockConsumableProductsHandler = MockMerchantConsumableProductHandler()
            mockConsumableProductsHandler.consumeProduct = { product, completion in
                completion()
            }

            let configuration = Merchant.Configuration(receiptValidator: mockReceiptValidator, storage: EphemeralPurchaseStorage())
    
            let merchant = Merchant(configuration: configuration, delegate: mockDelegate, consumableHandler: mockConsumableProductsHandler, storeInterface: mockStoreInterface)
            merchant.register(testProducts)
            merchant.setup()
            
            let delegate = MockProductInterfaceControllerDelegate()
            delegate.didRestore = { result in
                switch (result, expectedResult) {
                    case (.success(let a), .success(let b)) where a == b:
                        break
                    case (.failure(let a as MockError), .failure(let b as MockError)) where a == b:
                        break
                    case (.success(let products), .failure(let error)):
                        XCTFail("The restore purchases succeeded with products \(products) when it was expected to fail with error \(error).")
                    case (.failure(let error), .success(let products)):
                        XCTFail("The restore purchases failed with error \(error) when it was expected to succeed with products \(products).")
                    default:
                        XCTFail("The restore purchases finished with result \(result) when \(expectedResult) was expected.")
                }
                
                completionExpectation.fulfill()
                
                runNextResult()
            }
            
            let controller = ProductInterfaceController(products: Set(testProducts), with: merchant)
            controller.delegate = delegate
        
            self.productInterfaceController = controller
            self.productInterfaceControllerDelegate = delegate
            
            controller.restorePurchases()
        }
        
        runNextResult()
        
        self.wait(for: [completionExpectation], timeout: 5)
    }
    
    func testUserNotAllowedToMakePurchasesError() {
        let completionExpectation = self.expectation(description: "Completed.")

        let testProductsAndPurchases = self.testProductsAndPurchases()
        let testProducts = testProductsAndPurchases.map { $0.product }
        
        let mockDelegate = MockMerchantDelegate()
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.receiptFetchResult = .success(Data())
        mockStoreInterface.availablePurchasesResult = .failure(.userNotAllowedToMakePurchases)
        
        let mockConsumableProductsHandler = MockMerchantConsumableProductHandler()
        mockConsumableProductsHandler.consumeProduct = { product, completion in
            completion()
        }
        
        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: mockConsumableProductsHandler, storeInterface: mockStoreInterface)
        merchant.register(testProducts)
        merchant.setup()
            
        let delegate = MockProductInterfaceControllerDelegate()
        let controller = ProductInterfaceController(products: Set(testProducts), with: merchant)
        controller.delegate = delegate
        
        delegate.didChangeFetchingState = {
            switch controller.fetchingState {
                case .failed(.userNotAllowedToMakePurchases):
                    completionExpectation.fulfill()
                default:
                    break
            }
        }
        
        controller.fetchDataIfNecessary()
        
        self.wait(for: [completionExpectation], timeout: 5)
    }
    
    private var productInterfaceController: ProductInterfaceController!
    private var productInterfaceControllerDelegate: ProductInterfaceControllerDelegate!
}

extension ProductInterfaceControllerTests {
    private func testProductsAndPurchases() -> [(product: Product, purchase: Purchase)] {
        let kinds: [Product.Kind] = [.consumable, .nonConsumable, .subscription(automaticallyRenews: false), .subscription(automaticallyRenews: true)]
        
        return kinds.enumerated().map { i, kind in
            let identifier = "testProduct\(i)"
            
            let product = Product(identifier: identifier, kind: kind)
            let skProduct: SKProduct
            
            if case .subscription(automaticallyRenews: _) = kind, #available(iOS 11.2, *) {
                let subscriptionPeriod = MockSKProductSubscriptionPeriod(unit: .month, numberOfUnits: 1)
                
                skProduct = MockSKProductWithSubscription(productIdentifier: identifier, price: NSDecimalNumber(string: "0.99"), priceLocale: Locale(identifier: "en_US_POSIX"), subscriptionPeriod: subscriptionPeriod, introductoryOffer: nil)
            } else {
                skProduct = MockSKProduct(productIdentifier: identifier, price: NSDecimalNumber(string: "0.99"), priceLocale: Locale(identifier: "en_US_POSIX"))
            }

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
