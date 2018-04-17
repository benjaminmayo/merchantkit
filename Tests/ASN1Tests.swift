import XCTest
@testable import MerchantKit

class ASN1Tests : XCTestCase {
    func testObjectIdentifierCreation() {
        let data = Data(base64Encoded: "KoZIhvcNAQcC")!
        
        let identifier = ASN1.ObjectIdentifier(bytes: data)
        
        XCTAssertEqual(identifier.stringValue, "1.2.840.113549.1.7.2")
    }
    
    func testParseEmptyData() {
        let parser = ASN1.Parser(data: Data())
        
        XCTAssertThrowsError(try parser.parse())
    }
}
