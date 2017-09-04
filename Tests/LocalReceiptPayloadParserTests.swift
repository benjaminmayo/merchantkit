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
    
    func testSampleResources() {
        let singleExpectation = ReceiptExpectation(productIdentifiers: ["codeSharingUnlockable"], resourceName: "testSingleInAppPurchaseReceipt")
        
        let expectations = [singleExpectation]
        
        for expectation in expectations {
            let bundle = Bundle(for: type(of: self))
            
            guard
                let url = bundle.url(forResource: expectation.resourceName, withExtension: "data"),
                let base64String = try? String(contentsOf: url),
                let data = Data(base64Encoded: base64String)
            else { continue }
            
            let parser = LocalReceiptPayloadParser()
            
            var receipt: Receipt!
            XCTAssertNoThrow(receipt = try parser.receipt(from: data))
            
            XCTAssertEqual(receipt.productIdentifiers, expectation.productIdentifiers)
        }
    }
    
    struct ReceiptExpectation {
        let productIdentifiers: Set<String>
        let resourceName: String
    }
}


