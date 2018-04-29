import XCTest
import Foundation
@testable import MerchantKit

class LocalConfigurationTests : XCTestCase {
    func testMissingResource() {
        XCTAssertThrowsError(_ = try LocalConfiguration(fromResourceNamed: "missingResource", extension: "plist")) { error in
            switch error {
                case LocalConfiguration.Error.resourceNotFound:
                    break
                default:
                    XCTFail("unexpected error for missing resource: \(error)")
            }
        }
    }
    
    func testInvalidFormat() {
        let bundle = Bundle(for: type(of: self))

        XCTAssertThrowsError(_ = try LocalConfiguration(fromResourceNamed: "testInvalidFormatLocalConfiguration", extension: "plist", in: bundle)) { error in
            switch error {
                case LocalConfiguration.Error.invalidResourceFormat:
                    break
                default:
                    XCTFail("unexpected error for invalid format resource: \(error)")
            }
        }
    }
    
    func testMissingProductsArray() {
        let object: [String : Any] = [:]
        
        XCTAssertThrowsError(_ = try LocalConfiguration(from: object)) { error in
            switch error {
                case LocalConfiguration.Error.missingKey("Products"):
                    break
                default:
                    XCTFail("unexpected error for missing 'Products': \(error)")
            }
        }
    }
    
    func testIncorrectlyTypedProductsArray() {
        let object: [String : Any] = [
            "Products": [:]
        ]
        
        XCTAssertThrowsError(_ = try LocalConfiguration(from: object)) { error in
            switch error {
                case LocalConfiguration.Error.incorrectType(forKey: "Products", expected: _):
                    break
                default:
                    XCTFail("unexpected error for incorrectly typed 'Products': \(error)")
            }
        }
    }
    
    func testInvalidValueForProductKindIdentifier() {
        let object: [String : Any] = [
            "Products": [[
                "Identifier": "ProductIdentifier",
                "Kind": "InvalidKind"
            ]]
        ]
        
        XCTAssertThrowsError(_ = try LocalConfiguration(from: object)) { error in
            switch error {
                case LocalConfiguration.Error.invalidValue(forKey: "Kind", reason: "InvalidKind not recognized as a product kind"):
                    break
                default:
                    XCTFail("unexpected error for invalid product kind: \(error)")
            }
        }
    }
    
    func testSuccessfulInitializationWithNoUserInfo() {
        let object: [String : Any] = [
            "Products": [[
                "Identifier": "TestProduct",
                "Kind": "Consumable"
            ]]
        ]
        
        var localConfiguration: LocalConfiguration!
        XCTAssertNoThrow(localConfiguration = try LocalConfiguration(from: object))
        
        XCTAssertEqual(localConfiguration.products, [Product(identifier: "TestProduct", kind: .consumable)])
        
        XCTAssertTrue(localConfiguration.userInfo.isEmpty)
    }
    
    func testSuccessfulInitializationWithIncorrectUserInfoValue() {
        let object: [String : Any] = [
            "Products": [[
                "Identifier": "TestProduct",
                "Kind": "Consumable"
            ]],
            "User Info": "not a dictionary"
        ]
        
        var localConfiguration: LocalConfiguration!
        XCTAssertNoThrow(localConfiguration = try LocalConfiguration(from: object))
        
        XCTAssertEqual(localConfiguration.products, [Product(identifier: "TestProduct", kind: .consumable)])
        
        XCTAssertTrue(localConfiguration.userInfo.isEmpty)
    }
    
    func testSuccessfulInitializationWithValidUserInfo() {
        let object: [String : Any] = [
            "Products": [[
                "Identifier": "TestProduct",
                "Kind": "Consumable"
                ]],
            "User Info": ["Any Key" : "Any Value"]
        ]
        
        var localConfiguration: LocalConfiguration!
        XCTAssertNoThrow(localConfiguration = try LocalConfiguration(from: object))
        
        XCTAssertEqual(localConfiguration.products, [Product(identifier: "TestProduct", kind: .consumable)])
        
        let element = localConfiguration.userInfo.first
        XCTAssertNotNil(element)
        
        if element!.key != "Any Key" || (element!.value as? String) != "Any Value" {
            XCTFail("incorrect user info")
        }
    }
    
    func testSuccessfulInitializationFromResource() {
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
        
        let expectedUserInfo = ["Any Key" : "Any Value"] as [String : Any]
        
        let isEqualUserInfo = localConfiguration.userInfo.elementsEqual(expectedUserInfo, by: { (a, b) in
            guard a.key == b.key else { return false }
            guard let aValue = a.value as? AnyHashable, let bValue = b.value as? AnyHashable else { return false }
            
            return aValue == bValue
        })
        
        XCTAssertTrue(isEqualUserInfo, "userInfo not matches")
    }
}
