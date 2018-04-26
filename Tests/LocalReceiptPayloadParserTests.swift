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
        // TODO: Replace these resources with actual payload data resources; essentially the calls to `PKCS7ReceiptDataContainer` should not be part of this method.
        let twoNonconsumablesResource = SampleResource(name: "testSampleReceiptTwoNonConsumablesPurchased", expectedProductIdentifiers: ["codeSharingUnlockable", "saveScannedCodeUnlockable"])
        let subscriptionResource = SampleResource(name: "testSampleReceiptOneSubscriptionPurchased", expectedProductIdentifiers: ["premiumsubscription"])
        
        let resources = [twoNonconsumablesResource, subscriptionResource]
        
        for resource in resources {
            guard let receiptData = self.dataForSampleResource(withName: resource.name, extension: "data") else {
                XCTFail("sample resource not found");
                continue
            }
            
            let container = PKCS7ReceiptDataContainer(receiptData: receiptData)
            var payloadData: Data!
            
            XCTAssertNoThrow(payloadData = try container.content())

            let parser = LocalReceiptPayloadParser()
            var receipt: Receipt!
                
            XCTAssertNoThrow(receipt = try parser.receipt(from: payloadData))
            
            XCTAssertEqual(receipt.productIdentifiers, resource.expectedProductIdentifiers)
        }
    }
}


