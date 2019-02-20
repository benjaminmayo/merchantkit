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
    
    func testIncorrectInAppPurchaseSequenceErrorPropagated() {
        let inAppPurchaseData: Data = {
            var data = Data()
            data.append(ASN1.Parser.PayloadDescriptor(domain: .universal, tag: .type(.set), valueKind: .constructed).byte)
            data.append(12)
            data.append(ASN1.Parser.PayloadDescriptor(domain: .universal, tag: .type(.sequence), valueKind: .constructed).byte)
            data.append(10)
            data.append(ASN1.BufferType.integer.rawValue)
            data.append(2)
            data.append(0x06)
            data.append(0xA6)
            data.append(ASN1.BufferType.integer.rawValue)
            data.append(1)
            data.append(1)
            data.append(ASN1.BufferType.bitString.rawValue)
            data.append(0)
            data.append(0)
            
            return data
        }()
        
        let inAppPurchaseDataLength = UInt8(inAppPurchaseData.count)
        var data = Data()
        data.append(ASN1.Parser.PayloadDescriptor(domain: .universal, tag: .type(.set), valueKind: .constructed).byte)
        data.append(10 + inAppPurchaseDataLength)
        data.append(ASN1.Parser.PayloadDescriptor(domain: .universal, tag: .type(.sequence), valueKind: .constructed).byte)
        data.append(8 + inAppPurchaseDataLength)
        data.append(ASN1.Parser.PayloadDescriptor(domain: .universal, tag: .type(.integer), valueKind: .primitive).byte)
        data.append(1)
        data.append(17)
        data.append(ASN1.Parser.PayloadDescriptor(domain: .universal, tag: .type(.integer), valueKind: .primitive).byte)
        data.append(1)
        data.append(1)
        data.append(ASN1.Parser.PayloadDescriptor(domain: .universal, tag: .type(.octetString), valueKind: .primitive).byte)
        data.append(inAppPurchaseDataLength)
        data.append(contentsOf: inAppPurchaseData)
        
        let expectedError = ASN1.PayloadValueConversionError.invalidBufferSize(foundByteCount: 0, payloadType: .bitString)
        
        do {
            let parser = LocalReceiptPayloadParser()
            let receipt = try parser.receipt(from: data)
            
            XCTAssertTrue(receipt.productIdentifiers.isEmpty)
            XCTFail("The payload parsing succeeded when it was expected to fail with error \(expectedError).")
        } catch ASN1.PayloadValueConversionError.invalidBufferSize(foundByteCount: 0, payloadType: .bitString) {
            
        } catch let error {
            XCTFail("The payload parsing failed with error \(error) when it was expected to fail with error \(expectedError).")
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


