import XCTest
import Foundation
@testable import MerchantKit

class BucketsTests : XCTestCase {
    func testEmpty() {
        let buckets = Buckets<Int, String>()
        
        XCTAssertTrue(buckets.isEmpty)
    }
    
    func testSetBucketOneElement() {
        var buckets = Buckets<Int, String>()
        buckets[0] = ["a"]
        
        XCTAssertEqual(buckets.keys.count, 1)
        XCTAssertEqual(buckets[0], ["a"])
    }
    
    func testBucketInsertElementRemoveElement() {
        var buckets = Buckets<Int, String>()
        buckets[0] = ["a"]
        buckets[0] = []
        
        XCTAssertTrue(buckets.isEmpty)
    }
    
    func testRemoveAll() {
        var buckets = Buckets<Int, String>()
        buckets[0] = ["a", "b", "c"]
        
        buckets.removeAll()
        
        XCTAssertTrue(buckets.isEmpty)
    }
    
    func testInsertElementRemoveAllForKey() {
        var buckets = Buckets<Int, String>()
        buckets[0] = ["a", "b", "c"]
        buckets[1] = ["d", "e", "f"]
        
        buckets.removeAll(for: 1)
        
        XCTAssertTrue(!buckets.isEmpty)
        XCTAssertTrue(buckets.keys.count == 1)
        XCTAssertTrue(buckets[0] == ["a", "b", "c"])
    }
}
