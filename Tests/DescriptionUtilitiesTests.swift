import XCTest
import Foundation
@testable import MerchantKit

class DescriptionUtilitiesTest : XCTestCase {
    func testSimpleProperties() {
        let item = TestItem(a: 1, b: 2, string: "test")
        
        let description = item.description
        
        XCTAssertEqual(description, "[TestItem a: 1, b: 2, string: test]")
    }
    
    func testPropertiesWithNoName() {
        let item = TestItemWithUnnamedProperty(a: 1, b: 2, string: "test")
        
        let description = item.description
        
        XCTAssertEqual(description, "[TestItemWithUnnamedProperty a: 1, b: 2, test]")
    }
}

struct TestItem : CustomStringConvertible {
    let a: Int
    let b: Int
    let string: String
    
    var description: String {
        return self.defaultDescription(withProperties: ("a", self.a), ("b", self.b), ("string", self.string))
    }
}

struct TestItemWithUnnamedProperty : CustomStringConvertible {
    let a: Int
    let b: Int
    let string: String
    
    var description: String {
        return self.defaultDescription(withProperties: ("a", self.a), ("b", self.b), ("", self.string))
    }
}
