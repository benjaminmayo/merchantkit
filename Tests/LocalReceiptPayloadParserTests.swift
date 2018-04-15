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
    
    struct ReceiptExpectation {
        let productIdentifiers: Set<String>
        let resource: (name: String, `extension`: String)
    }
}


