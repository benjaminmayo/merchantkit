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
    
    func testSubscriptionSampleResources() {
        let expectation = ReceiptExpectation(productIdentifiers: ["testsubscription"], resource: (name: "testSubscriptionReceiptResponse", extension: "json"))
        let expectations = [expectation]
        
        let bundle = Bundle(for: type(of: self))

        for expectation in expectations {
            guard let url = bundle.url(forResource: expectation.resource.name, withExtension: expectation.resource.extension), let data = try? Data(contentsOf: url) else {
                XCTFail("sample resource \(expectation.resource.name) not exists")
                continue
            }
            
            let parser = ServerReceiptVerificationResponseParser()
            
            var response: ServerReceiptVerificationResponseParser.Response!
            XCTAssertNoThrow(response = try parser.response(from: data))
            
            var receipt: Receipt!
            XCTAssertNoThrow(receipt = try parser.receipt(from: response))
    
            XCTAssertEqual(receipt.productIdentifiers, expectation.productIdentifiers)
        }
    }
    
    struct ReceiptExpectation {
        let productIdentifiers: Set<String>
        let resource: (name: String, `extension`: String)
    }
}


