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
        randomData.withUnsafeMutableBytes({ buffer in
            for idx in buffer.indices {
                buffer[idx] = UInt8.random(in: .min ... .max)
            }
        })
                
        let parser = LocalReceiptPayloadParser()
        
        XCTAssertThrowsError(try parser.receipt(from: randomData))
    }
    
    func testUnrecognisedReceiptAttributeProcessorDelegateCallback() {
        let processor = ReceiptAttributeASN1SetProcessor(data: Data())
        let attribute = ReceiptAttributeASN1SetProcessor.ReceiptAttribute(type: 0, version: 0, data: Data())
        
        let expectation = self.expectation(description: "fatalError thrown")

        MerchantKitFatalError.customHandler = {
            expectation.fulfill()
        }
        
        let testingQueue = DispatchQueue(label: "testing queue") // testing MerchantKitFatalError requires dispatch to a non-main thread

        testingQueue.async {
            let parser = LocalReceiptPayloadParser()
            parser.receiptAttributeASN1SetProcessor(processor, didFind: attribute)
        }
        
        self.wait(for: [expectation], timeout: 1)
    }
    
    private struct SampleResource {
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


