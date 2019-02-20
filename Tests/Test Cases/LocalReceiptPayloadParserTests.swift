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
        
        MerchantKitFatalError.customHandler = nil 
    }
    
    func testIncorrectReceiptMetadataAttributeTypeHandledGracefully() {
        var data = Data()
        data.append(ASN1.Parser.PayloadDescriptor(domain: .universal, tag: .type(.set), valueKind: .constructed).byte)
        data.append(13)
        data.append(ASN1.Parser.PayloadDescriptor(domain: .universal, tag: .type(.sequence), valueKind: .constructed).byte)
        data.append(11)
        data.append(ASN1.BufferType.integer.rawValue)
        data.append(1)
        data.append(19)
        data.append(ASN1.BufferType.integer.rawValue)
        data.append(1)
        data.append(1)
        data.append(ASN1.BufferType.bitString.rawValue)
        data.append(3)
        data.append(ASN1.BufferType.integer.rawValue)
        data.append(1)
        data.append(42)
        
        do {
            let parser = LocalReceiptPayloadParser()
            let receipt = try parser.receipt(from: data)
            
            XCTAssertEqual(receipt.metadata.originalApplicationVersion, "", "The originalApplicationVersion was \(receipt.metadata.originalApplicationVersion) when an empty string was expected.")
        } catch let error {
            XCTFail("The parser failed with error \(error) when it was expected to succeed.")
        }
    }
    
    func testSampleResources() {
        struct SampleResource {
            let name: String
            let expectedProductIdentifiers: Set<String>
        }
        
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


