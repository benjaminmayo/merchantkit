import XCTest
import Foundation
@testable import MerchantKit

class ASN1Tests : XCTestCase {
    func testObjectIdentifierCreation() {
        let data = Data(base64Encoded: "KoZIhvcNAQcC")!
        
        let identifier = ASN1.ObjectIdentifier(bytes: data)
        
        XCTAssertEqual(identifier.stringValue, "1.2.840.113549.1.7.2")
        XCTAssertEqual(identifier.description, "[ASN1.ObjectIdentifier stringValue: 1.2.840.113549.1.7.2]")
    }
    
    func testObjectIdentifierWithNilStringValue() {
        let data = Data([255, 255])
        
        let identifier = ASN1.ObjectIdentifier(bytes: data)
        
        XCTAssertNil(identifier.stringValue)
        XCTAssertEqual(identifier.description, "[ASN1.ObjectIdentifier stringValue: nil]")
    }
    
    func testParseEmptyData() {
        let parser = ASN1.Parser(data: Data())
        
        XCTAssertThrowsError(try parser.parse())
    }
    
    func testEmptyBufferConversion() {
        let bufferTypesNotAllowedToConvertFromEmptyBuffers: Set<ASN1.BufferType> = [.eoc, .boolean, .integer, .bitString, .octetString, .objectIdentifier, .objectDescriptor, .externalReference, .real, .enumerated, .embeddedPDV, .relativeObjectIdentifier, .sequence, .set, .numericString, .videoTextString, .utcTime, .generalizedTime, .visibleString, .generalString, .universalString, .bitmapString, .usesLongForm]
        
        for bufferType in bufferTypesNotAllowedToConvertFromEmptyBuffers {
            XCTAssertThrowsError(try ASN1.value(convertedFrom: Data(), as: bufferType)) { error in
                switch error {
                    case ASN1.PayloadValueConversionError.invalidBufferSize(foundByteCount: 0, payloadType: bufferType):
                        break
                    case let error:
                        XCTFail("unexpected error for empty buffer: \(error)")
                }
            }
        }
    }
    
    func testSuccessfulBooleanBufferConversion() {
        let trueBuffer = Data([1])
        let falseBuffer = Data([0])
        
        XCTAssertEqual(try ASN1.value(convertedFrom: trueBuffer, as: .boolean), ASN1.BufferValue.boolean(true))
        XCTAssertEqual(try ASN1.value(convertedFrom: falseBuffer, as: .boolean), ASN1.BufferValue.boolean(false))
    }
    
    func testInvalidBooleanBufferConversion() {
        let invalidBuffer = Data([0, 1])
        
        XCTAssertThrowsError(try ASN1.value(convertedFrom: invalidBuffer, as: .boolean)) { error in
            switch error {
                case ASN1.PayloadValueConversionError.invalidBufferSize(foundByteCount: 2, payloadType: .boolean):
                    break
                default:
                    XCTFail("unexpected error for invalid boolean buffer: \(error)")
            }
        }
    }
    
    func testSuccessfulStringBufferConversion() {
        let stringTypes: Set<ASN1.BufferType> = [.teletexString, .graphicString, .printableString, .utf8String, .ia5String]
        
        for bufferType in stringTypes {
            let testString = "The quick brown fox jumped over the lazy dog."
            let data = testString.data(using: .utf8)!
            
            var value: ASN1.BufferValue!
            XCTAssertNoThrow(value = try ASN1.value(convertedFrom: data, as: bufferType))
            
            XCTAssertEqual(value, .string(testString))
        }
    }
    
    func testInvalidStringBufferConversion() {
        let stringTypes: Set<ASN1.BufferType> = [.teletexString, .graphicString, .printableString, .utf8String, .ia5String]
        
        for bufferType in stringTypes {
            let invalidData = Data([0xff, 0xff])
            
            XCTAssertThrowsError(_ = try ASN1.value(convertedFrom: invalidData, as: bufferType)) { error in
                switch error {
                    case ASN1.PayloadValueConversionError.unsupportedBuffer(payloadType: bufferType):
                        break
                    case let error:
                        XCTFail("unexpected error for invalid string buffer: \(error)")
                }
            }
        }
    }
    
    func testBufferValueDescription() {
        let expectations: [(ASN1.BufferValue, String)] = [
            (.null, "null"),
            (.boolean(true), "true"),
            (.integer(123), "123"),
            (.string("test"), "'test'"),
            (.data(Data()), "0 bytes"),
            (.date("01-02-2000"), "'01-02-2000'"),
            (.objectIdentifier(ASN1.ObjectIdentifier(bytes: Data([0xFF, 0x4, 0x8, 0x16]))), "[ASN1.ObjectIdentifier stringValue: 6.15.4.8.22]")
        ]
        
        for (value, formattedDescriptionComponent) in expectations {
            let expectedDescription = "[ASN1.BufferValue value: \(formattedDescriptionComponent)]"
            
            XCTAssertEqual(String(describing: value), expectedDescription)
        }
    }
    
    func testGenerateAllPayloadDescriptors() {
        for byte: UInt8 in 0...255 { // exhaustively check for no weirdness like crashes
            let _ = ASN1.Parser.PayloadDescriptor(from: byte)
        }
    }
    
    func testCustomTagsForPayloadDescriptors() {
        let customTagComponents: [UInt8] = [14, 15, 29]
        
        for byte in customTagComponents {
            let descriptor = ASN1.Parser.PayloadDescriptor(from: byte)
            
            switch descriptor.tag {
                case .custom(let value):
                    XCTAssertEqual(value, byte)
                case .type(let bufferType):
                    XCTFail("The byte \(byte) was resolved to tag type \(bufferType), when a custom field was expected.")
            }
            
            XCTAssertEqual(byte, descriptor.tag.rawType, "The tag raw type is \(descriptor.tag.rawType), when \(byte) was expected.")
            XCTAssertNil(descriptor.tag.type, "The tag was resolved to a tag type, when it should be `nil` as the tag is a custom field.")
        }
    }
    
    func testPayloadDescriptorWithTagDoesNotAffectOtherProperties() {
        let descriptor = ASN1.Parser.PayloadDescriptor(from: 14)

        let newDescriptor = descriptor.withTag(.type(.generalString))
        
        XCTAssertEqual(newDescriptor.tag, ASN1.Parser.PayloadDescriptor.Tag.type(ASN1.BufferType.generalString))
        XCTAssertEqual(descriptor.domain, newDescriptor.domain)
        XCTAssertEqual(descriptor.valueKind, newDescriptor.valueKind)
    }
    
    func testParserConsumeWithInvalidLengthNoMoreData() {
        do {
            let data = Data([2])
            
            let parser = ASN1.Parser(data: data)
            
            try parser.parse()
        } catch ASN1.PayloadValueConversionError.invalidLength {
            
        } catch let error {
            XCTFail("The parse failed with \(error) when a failure with error \(ASN1.PayloadValueConversionError.invalidLength) was expected.")
        }
    }
    
    
    
    func testTimeBufferTypeConversion() {
        for type in [ASN1.BufferType.generalizedTime, ASN1.BufferType.utcTime] {
            let asciiText = "this is a test"
            let asciiData = asciiText.data(using: .ascii)!
            
            var result: ASN1.BufferValue!
            
            XCTAssertNoThrow(result = try ASN1.value(convertedFrom: asciiData, as: type))
            
            XCTAssertEqual(result, .date(asciiText))
        }
    }
    
    func testStringBufferTypeConversion() {
        for type in [ASN1.BufferType.teletexString, .graphicString, .printableString, .utf8String, .ia5String] {
            let asciiText = "this is a test"
            let asciiData = asciiText.data(using: .utf8)!
            
            var result: ASN1.BufferValue!
            
            XCTAssertNoThrow(result = try ASN1.value(convertedFrom: asciiData, as: type))
            
            XCTAssertEqual(result, .string(asciiText))
            
            let failingData = Data([67, 97, 102, 195])
            
            XCTAssertThrowsError(result = try ASN1.value(convertedFrom: failingData, as: type))
        }
    }
    
    func testInvalidBufferTypeConversion() {
        let unsupportedBufferTypes = [ASN1.BufferType.eoc, .objectDescriptor, .externalReference, .real, .enumerated, .embeddedPDV, .sequence, .set, .numericString, .videoTextString, .visibleString, .generalString, .universalString, .bitmapString, .usesLongForm]
        
        for type in unsupportedBufferTypes {
            let data = Data([1, 2, 3])
            
            XCTAssertThrowsError(_ = try ASN1.value(convertedFrom: data, as: type))
        }
    }
    
    func testDataBufferTypeConversion() {
        for type in [ASN1.BufferType.bitString, .octetString] {
            let data = Data([1, 2, 3])
            var result: ASN1.BufferValue!

            XCTAssertNoThrow(result = try ASN1.value(convertedFrom: data, as: type))
            XCTAssertEqual(result, .data(data))
        }
    }
    
    func testThrowsConsumeLengthBecauseInfinite() {
        let empty = Data([128])
        
        XCTAssertThrowsError(_ = try ASN1.consumeLength(from: empty), "An infinite length should be not supported.", { error in
            switch error {
                case ASN1.PayloadValueConversionError.invalidLength:
                    break
                case let error:
                    XCTFail("The `ASN1.consumeLength(from:)` conversion failed with error \(error) but the error \(ASN1.PayloadValueConversionError.invalidLength) was expected.")
            }
        })
    }
    
    func testThrowsConsumeLengthBecauseInvalidLength() {
        let data = Data([130])
        
        XCTAssertThrowsError(_ = try ASN1.consumeLength(from: data), "An invalid length buffer value should be not supported.", { error in
            switch error {
                case ASN1.PayloadValueConversionError.invalidLength:
                    break
                case let error:
                    XCTFail("The `ASN1.consumeLength(from:)` conversion failed with error \(error) but the error \(ASN1.PayloadValueConversionError.invalidLength) was expected.")
            }
        })
    }
    
    func testThrowsConsumeLengthBecauseLengthSmallerOrEqualToZero() {
        let data = Data([129, 0, 0])
        
        XCTAssertThrowsError(_ = try ASN1.consumeLength(from: data), "A buffer value should be not supported.", { error in
            switch error {
                case ASN1.PayloadValueConversionError.invalidLength:
                    break
                case let error:
                    XCTFail("The `ASN1.consumeLength(from:)` conversion failed with error \(error) but the error \(ASN1.PayloadValueConversionError.invalidLength) was expected.")
            }
        })
    }
}
