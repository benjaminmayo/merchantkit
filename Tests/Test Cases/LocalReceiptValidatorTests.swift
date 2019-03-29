import XCTest
@testable import MerchantKit

class LocalReceiptValidatorTests : XCTestCase {
    struct SampleResource {
        let name: String
        let expectedProductIdentifiers: Set<String>
        let expectedOriginalApplicationVersion: String
    }
    
    func testSampleResources() {
        let twoNonconsumablesResource = SampleResource(name: "testSampleReceiptTwoNonConsumablesPurchased", expectedProductIdentifiers: ["codeSharingUnlockable", "saveScannedCodeUnlockable"], expectedOriginalApplicationVersion: "26")
        let subscriptionResource = SampleResource(name: "testSampleReceiptOneSubscriptionPurchased", expectedProductIdentifiers: ["premiumsubscription"], expectedOriginalApplicationVersion: "1.0.21")
        
        let resources = [twoNonconsumablesResource, subscriptionResource]
        
        for resource in resources {
            guard let data = self.dataForSampleResource(withName: resource.name, extension: "data") else {
                XCTFail("sample resource not found")
                continue
            }
            
            let expectation = self.expectation(description: resource.name)
            
            let request = ReceiptValidationRequest(data: data, reason: .initialization)
            
            
            let validator = LocalReceiptValidator()
            validator.validate(request, completion: { result in
                switch result {
                    case .success(let receipt):
                        XCTAssertEqual(receipt.metadata.originalApplicationVersion, resource.expectedOriginalApplicationVersion)
                        XCTAssertEqual(receipt.productIdentifiers, resource.expectedProductIdentifiers)
                    case .failure(let error):
                        XCTFail(String(describing: error))
                }
                
                expectation.fulfill()
            })
            
            self.wait(for: [expectation], timeout: 5)
        }
    }
}


