import XCTest
import Foundation
@testable import MerchantKit

class LocalConfigurationTests : XCTestCase {
    func testMissingResource() {
        XCTAssertThrowsError(_ = try LocalConfiguration(fromResourceNamed: "missingResource", extension: "plist")) { error in
            switch error {
                case LocalConfiguration.ResourceError.notFound:
                    break
                default:
                    XCTFail("unexpected error for missing resource: \(error)")
            }
        }
    }
    
    func testParseSampleResourceSuccessfully() {
        let bundle = Bundle(for: type(of: self))

        var localConfiguration: LocalConfiguration!
        XCTAssertNoThrow(localConfiguration = try LocalConfiguration(fromResourceNamed: "testLocalConfiguration", extension: "plist", in: bundle))
        
        XCTAssertEqual(localConfiguration.products.count, 4)
        
        let expectations: [(String, Product.Kind)] = [
            ("nonConsumableIdentifier", .nonConsumable),
            ("consumableIdentifier", .consumable),
            ("subscriptionIdentifier", .subscription(automaticallyRenews: false)),
            ("automaticallyRenewingSubscriptionIdentifier", .subscription(automaticallyRenews: true))
        ]
        
        for (identifier, kind) in expectations {
            let product = localConfiguration.product(withIdentifier: identifier)
            
            XCTAssertNotNil(product)
            
            XCTAssertEqual(product!.kind, kind)
        }
    }
}
