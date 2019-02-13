import XCTest
@testable import MerchantKit

class MerchantTaskProcedureTests : XCTestCase {
    func testSuccessfulFetchPurchaseAndPurchaseProduct() {
        let productsAndPurchases = self.testProductsAndPurchases()
        
        let commitPurchaseResults: [String : Result<Void, Error>] = Dictionary(uniqueKeysWithValues: productsAndPurchases.map { ($0.0.identifier, .success) })
        let availablePurchases = PurchaseSet(from: productsAndPurchases.map { $0.1 })
    
        let outcomes = productsAndPurchases.map { $0.0 }.map { ProductExpectedOutcome(for: $0, finalState: .isPurchased(PurchasedProductInfo(expiryDate: nil)), isPurchaseExists: true, isSuccessfulCommit: true) }
        
        self.runTest(
            with: outcomes,
            availablePurchasesResult: Result<PurchaseSet, MockError>.success(availablePurchases),
            commitPurchaseResults: commitPurchaseResults
        )
    }
    
    func testFailureToFetch() {
        let productsAndPurchases = self.testProductsAndPurchases()
        let outcomes = productsAndPurchases.map { $0.product }.map { ProductExpectedOutcome(for: $0, finalState: .notPurchased, isPurchaseExists: false, isSuccessfulCommit: false) }

        self.runTest(with: outcomes, availablePurchasesResult: .failure(MockError.mockError), commitPurchaseResults: [:])
    }
    
    func testSuccessfulFetchAndFailureToPurchase() {
        let productsAndPurchases = self.testProductsAndPurchases()
        
        let commitPurchaseResults: [String : Result<Void, Error>] = Dictionary(uniqueKeysWithValues: productsAndPurchases.map { ($0.0.identifier, .failure(MockError.mockError)) })
        let availablePurchases = PurchaseSet(from: productsAndPurchases.map { $0.1 })
        
        let outcomes = productsAndPurchases.map { $0.0 }.map { ProductExpectedOutcome(for: $0, finalState: .notPurchased, isPurchaseExists: true, isSuccessfulCommit: false) }
        
        self.runTest(
            with: outcomes,
            availablePurchasesResult: Result<PurchaseSet, MockError>.success(availablePurchases),
            commitPurchaseResults: commitPurchaseResults
        )
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
    
    private func runTest<AvailablePurchasesError>(with expectedOutcomes: [ProductExpectedOutcome], availablePurchasesResult: Result<PurchaseSet, AvailablePurchasesError>, commitPurchaseResults: [String : Result<Void, Error>]) where AvailablePurchasesError : Error & Equatable {
        let products = Set(expectedOutcomes.map { $0.product })
        XCTAssertEqual(products.count, expectedOutcomes.count)
        
        let completionExpectation = self.expectation(description: "Async expectation")
        completionExpectation.expectedFulfillmentCount = expectedOutcomes.count
        
        let mockDelegate = MockMerchantDelegate()
        let mockStoreInterface = MockStoreInterface()
        mockStoreInterface.availablePurchasesResult = availablePurchasesResult.mapError { $0 as Error }
        mockStoreInterface.receiptFetchResult = .success(Data())
        
        let merchant = Merchant(configuration: .usefulForTestingAsPurchasedStateResetsOnApplicationLaunch, delegate: mockDelegate, consumableHandler: nil, storeInterface: mockStoreInterface)
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
                        if let foundError = error as? AvailablePurchasesError {
                            if foundError != expectedError {
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
        
        self.wait(for: [completionExpectation], timeout: 10)
    }
    
    private func testProductsAndPurchases(forKinds kinds: [Product.Kind] = [.nonConsumable, .subscription(automaticallyRenews: false), .subscription(automaticallyRenews: true)]) -> [(product: Product, purchase: Purchase)] {
        return kinds.enumerated().map { i, kind in
            let identifier = "testProduct\(i)"
            
            let product = Product(identifier: identifier, kind: kind)
            let skProduct = MockSKProduct(productIdentifier: identifier, price: NSDecimalNumber(string: "0.99"), priceLocale: Locale(identifier: "en_US_POSIX"))
            let purchase = Purchase(from: .availableProduct(skProduct), for: product)
            
            return (product: product, purchase: purchase)
        }
    }
    
    private enum MockError : Swift.Error {
        case mockError
    }
}
