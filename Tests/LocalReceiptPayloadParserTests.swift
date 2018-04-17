import XCTest
@testable import MerchantKit

class LocalReceiptPayloadParserTests : XCTestCase {
    func testEmptyData() {
        let empty = Data()
        
        let parser = LocalReceiptPayloadParser()
        XCTAssertThrowsError(try parser.receipt(from: empty))
    }
    
    func testRandomData() {
        let count = 512
        var randomData = Data(count: count)
        
        randomData.withUnsafeMutableBytes({ (bytes: UnsafeMutablePointer<UInt8>) in
            _ = SecRandomCopyBytes(kSecRandomDefault, count, bytes)
        })
        
        let parser = LocalReceiptPayloadParser()
        
        XCTAssertThrowsError(try parser.receipt(from: randomData))
    }
    
    struct SampleResource {
        let name: String
        let expectedProductIdentifiers: Set<String>
    }
    
    func testSampleResources() {
        let twoNonconsumabkesResource = SampleResource(name: "testSampleReceiptTwoNonconsumblesPurchased", expectedProductIdentifiers: ["codeSharingUnlockable", "saveScannedCodeUnlockable"])
        let subscriptionResource = SampleResource(name: "testSampleReceiptOneSubscriptionPurchased", expectedProductIdentifiers: ["premiumsubscription"])
        
        let resources = [twoNonconsumabkesResource, subscriptionResource]
        
        for resource in resources {
            let resourceURL = self.urlForSampleResource(withName: resource.name, extension: "data")
            
            guard let data = try? Data(contentsOf: resourceURL) else {
                XCTFail("no data at \(resourceURL)");
                continue
            }
            
            let expectation = self.expectation(description: resource.name)
            
            let validator = LocalReceiptValidator(request: .init(data: data, reason: .initialization))
            validator.onCompletion = { result in
                switch result {
                    case .succeeded(let receipt):
                        debugPrint(receipt)
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


