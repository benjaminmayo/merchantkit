import XCTest
@testable import MerchantKit

class TestingReceiptValidatorTests : XCTestCase {
    func testWrappingLeeway() {
        let possibleLeeways: [ReceiptValidatorSubscriptionRenewalLeeway] = [
            .default,
            .init(allowedElapsedDuration: 0),
            .init(allowedElapsedDuration: 60 * 60 * 24 * 7)
        ]
        
        for leeway in possibleLeeways {
            let mockValidator = MockReceiptValidator()
            mockValidator.subscriptionRenewalLeeway = leeway
            
            let testingValidator = TestingReceiptValidator(wrapping: mockValidator)
            
            XCTAssertEqual(leeway, testingValidator.subscriptionRenewalLeeway)
        }
    }
    
    func testValidateBehaviorFailsOnInitializationPassthroughOtherwise() {
        let mockReceipt = ConstructedReceipt(from: [], metadata: .init(originalApplicationVersion: "1", bundleIdentifier: "", creationDate: Date()))
        
        let mockValidator = MockReceiptValidator()
        mockValidator.validateRequest = { (_, completion) in
            completion(.success(mockReceipt))
        }
        
        let testingValidator = TestingReceiptValidator(wrapping: mockValidator)

        let initializationRequest = ReceiptValidationRequest(data: Data(), reason: .initialization)
        let expectationForInitialization = self.expectation(description: "Encountered `TestingReceiptValidator.Error.failingInitializationOnPurposeForTesting`")
        
        testingValidator.validate(initializationRequest, completion: { result in
            switch result {
                case .failure(TestingReceiptValidator.Error.failingInitializationOnPurposeForTesting):
                    expectationForInitialization.fulfill()
                default:
                    break
            }
        })
        
        self.wait(for: [expectationForInitialization], timeout: 5)
        
        let otherReasons: [ReceiptValidationRequest.Reason] = [.restorePurchases, .completePurchase]
        var expectations = [XCTestExpectation]()
        
        for reason in otherReasons {
            let otherRequest = ReceiptValidationRequest(data: Data(), reason: reason)
            let expectationForOtherRequest = self.expectation(description: "Receipt validation succeeded and returned matching `mockReceipt`.")

            testingValidator.validate(otherRequest, completion: { result in
                switch result {
                    case .success(let receipt) where receipt.metadata == mockReceipt.metadata:
                        expectationForOtherRequest.fulfill()
                    default:
                        break
                }
            })
            
            expectations.append(expectationForOtherRequest)
        }
        
        self.wait(for: expectations, timeout: 5)
    }
}
