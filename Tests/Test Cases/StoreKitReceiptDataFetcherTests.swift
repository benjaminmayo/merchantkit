import XCTest
import StoreKit
@testable import MerchantKit

internal class StoreKitReceiptDataFetcherTests : XCTestCase {
    func testOnlyFetchError() {
        let completionExpectation = self.expectation(description: "Fetch completed.")
        
        let fetcher = StoreKitReceiptDataFetcher(policy: .onlyFetch)
        fetcher.enqueueCompletion({ result in
            switch result {
                case .success(let data):
                    XCTFail("The fetcher succeeded with data \(data) when it was expected to fail with error \(ReceiptFetchError.receiptUnavailableWithoutRefresh).")
                case .failure(ReceiptFetchError.receiptUnavailableWithoutRefresh):
                    break
                case .failure(let error):
                    XCTFail("The fetcher failed with error \(error) when it was expected to fail with error \(ReceiptFetchError.receiptUnavailableWithoutRefresh).")
            }
            
            completionExpectation.fulfill()
        })
        
        fetcher.start()
        
        self.wait(for: [completionExpectation], timeout: 5)
    }
    
    func testSimulateRequestFinishedWithLogicErrorFatalErrorThrown() {
        let completionExpectation = self.expectation(description: "Fatal error thrown.")

        MerchantKitFatalError.customHandler = {
            completionExpectation.fulfill()
        }
        
        DispatchQueue.global(qos: .background).async {
            let fetcher = StoreKitReceiptDataFetcher(policy: .alwaysRefresh)
            fetcher.requestDidFinish(SKRequest())
        }
        
        self.wait(for: [completionExpectation], timeout: 4)
        
        MerchantKitFatalError.customHandler = nil
    }
    
    func testSimulateRequestFailure() {
        let policies: [ReceiptFetchPolicy] = [.alwaysRefresh, .fetchElseRefresh, .onlyFetch]
        let completionExpectation = self.expectation(description: "Completed fetch.")
        completionExpectation.expectedFulfillmentCount = policies.count
        
        for policy in policies {
            let fetcher = StoreKitReceiptDataFetcher(policy: policy)
            fetcher.enqueueCompletion({ result in
                switch result {
                    case .failure(MockError.mockError):
                        break
                    case .success(let data):
                        XCTFail("The fetcher succeeded with data \(data) when it was expected to fail with error \(MockError.mockError).")
                    case .failure(let error):
                        XCTFail("The fetcher failed with \(error) when it was expected to fail with error \(MockError.mockError).")
                }
                
                completionExpectation.fulfill()
            })
            
            fetcher.request(SKRequest(), didFailWithError: MockError.mockError)
        }
        
        self.wait(for: [completionExpectation], timeout: 4)
    }
    
    func testCancelFinishesFetcher() {
        let policies: [ReceiptFetchPolicy] = [.alwaysRefresh, .fetchElseRefresh, .onlyFetch]

        for policy in policies {
            let fetcher = StoreKitReceiptDataFetcher(policy: policy)
            fetcher.start()
            fetcher.cancel()
            
            XCTAssertTrue(fetcher.isFinished, "The fetcher should be finished as `cancel()` was called.")
        }
    }
}
