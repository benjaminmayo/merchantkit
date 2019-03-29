import XCTest
@testable import MerchantKit

class ReceiptAttributeASN1SetProcessorTests : XCTestCase {
    func testEmptyBuffersFail() {
        let attribute = ReceiptAttributeASN1SetProcessor.ReceiptAttribute(type: 1, version: 1, data: Data())
        XCTAssertNil(attribute.stringValue)
        XCTAssertNil(attribute.integerValue)
    }
    
    func testBuffersFailWithTagByteButEmptyData() {
        let bufferTypes: [ASN1.BufferType] = [.integer, .bitString, .octetString]
        
        for type in bufferTypes {
            let data = Data([type.rawValue])
            
            let attribute = ReceiptAttributeASN1SetProcessor.ReceiptAttribute(type: 1, version: 1, data: data)
            XCTAssertNil(attribute.stringValue)
            XCTAssertNil(attribute.integerValue)
        }
    }
    
    func testBuffersFailWithTagByteButIncorrectLengthForRemainingData() {
        let bufferTypes: [ASN1.BufferType] = [.integer, .bitString, .octetString]
        
        for type in bufferTypes {
            let data = Data([type.rawValue, 8, 0])
            
            let attribute = ReceiptAttributeASN1SetProcessor.ReceiptAttribute(type: 1, version: 1, data: data)
            XCTAssertNil(attribute.stringValue)
            XCTAssertNil(attribute.integerValue)
        }
    }
    
    func testBufferStringValueNotConvertibleToUTF8() {
        let bufferTypes: [ASN1.BufferType] = [.teletexString, .graphicString, .printableString, .utf8String, .ia5String]
        let invalidData = Data([0xff, 0xff])

        for type in bufferTypes {
            let data = Data([type.rawValue, UInt8(invalidData.count)]) + invalidData
            
            let attribute = ReceiptAttributeASN1SetProcessor.ReceiptAttribute(type: 1, version: 1, data: data)
            XCTAssertNil(attribute.stringValue)
        }
    }
    
    func testBufferIntegerValueFailsForStringValue() {
        let bufferTypes: [ASN1.BufferType] = [.teletexString, .graphicString, .printableString, .utf8String, .ia5String]
        let testString = "the quick brown fox jumped over the lazy dog"
        let testData = testString.data(using: .ascii)!
        
        for type in bufferTypes {
            let data = Data([type.rawValue, UInt8(testData.count)]) + testData
            
            let attribute = ReceiptAttributeASN1SetProcessor.ReceiptAttribute(type: 1, version: 1, data: data)
            XCTAssertNil(attribute.integerValue)
        }
    }
    
    func testBufferStringValueSucceeds() {
        let bufferTypes: [ASN1.BufferType] = [.teletexString, .graphicString, .printableString, .utf8String, .ia5String]
        let testString = "the quick brown fox jumped over the lazy dog"
        let testData = testString.data(using: .ascii)!
        
        for type in bufferTypes {
            let data = Data([type.rawValue, UInt8(testData.count)]) + testData
            
            let attribute = ReceiptAttributeASN1SetProcessor.ReceiptAttribute(type: 1, version: 1, data: data)
            XCTAssertNotNil(attribute.stringValue)
            
            if let stringValue = attribute.stringValue {
                XCTAssertEqual(stringValue, testString)
            }
        }
    }
    
    func testBufferIntegerValueSucceeds() {
        let bufferTypes: [ASN1.BufferType] = [.integer]
        let testInteger = 42
        let testData = Data([UInt8(testInteger)])
        
        for type in bufferTypes {
            let data = Data([type.rawValue, 1]) + testData
            
            let attribute = ReceiptAttributeASN1SetProcessor.ReceiptAttribute(type: 1, version: 1, data: data)
            XCTAssertNotNil(attribute.integerValue)
            
            if let integerValue = attribute.integerValue {
                XCTAssertEqual(integerValue, testInteger)
            }
        }
    }
    
    func testProcessorIgnoresUnexpectedBufferValues() {
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
        data.append(ASN1.BufferType.null.rawValue) // null is unhandled by processor but should not throw an error
        data.append(1)
        data.append(0)
        
        let processor = ReceiptAttributeASN1SetProcessor(data: data)
        XCTAssertNoThrow(try processor.start())
    }
}
