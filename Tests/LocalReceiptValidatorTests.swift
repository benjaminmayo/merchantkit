import XCTest
@testable import MerchantKit

class LocalReceiptValidatorTests : XCTestCase {
    struct SampleResource {
        let name: String
        let expectedProductIdentifiers: Set<String>
    }
    
    func testSampleResources() {
        let twoNonconsumablesResource = SampleResource(name: "testSampleReceiptTwoNonConsumablesPurchased", expectedProductIdentifiers: ["codeSharingUnlockable", "saveScannedCodeUnlockable"])
        let subscriptionResource = SampleResource(name: "testSampleReceiptOneSubscriptionPurchased", expectedProductIdentifiers: ["premiumsubscription"])
        
        let resources = [twoNonconsumablesResource, subscriptionResource]
        
        for resource in resources {
            guard let data = self.dataForSampleResource(withName: resource.name, extension: "data") else {
                XCTFail("sample resource not found")
                continue
            }
            
            let expectation = self.expectation(description: resource.name)
            
            let validator = LocalReceiptValidator(request: .init(data: data, reason: .initialization))
            validator.onCompletion = { result in
                switch result {
                    case .succeeded(let receipt):
                        XCTAssertEqual(receipt.productIdentifiers, resource.expectedProductIdentifiers)
                    case .failed(let error):
                        XCTFail(String(describing: error))
                }
                
                expectation.fulfill()
            }
            
            validator.start()
            
            self.wait(for: [expectation], timeout: 5)
        }
    }
}


