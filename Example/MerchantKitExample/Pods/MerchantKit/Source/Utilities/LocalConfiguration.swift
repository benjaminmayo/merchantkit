import Foundation

/// Use `LocalConfiguration` to load `Product` models and other metadata from a file resource. Find `testLocationConfiguration.plist` for an example format. I promise I'll add formal documentation eventually.
public struct LocalConfiguration {
    public let products: Set<Product>
    public let userInfo: [String : Any]
    
    public init(fromResourceNamed resourceName: String, extension: String, in bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: resourceName, withExtension: `extension`) else {
            throw Error.resourceNotFound
        }
    
        let data = try Data(contentsOf: url)
        
        let propertyList = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        
        guard let object = propertyList as? [String : Any] else { throw Error.invalidResourceFormat }
        
        try self.init(from: object)
    }
    
    internal init(from object: [String : Any]) throws {
        let productsCollection = try requiredValue(for: "Products", in: object, ofType: [[String : Any]].self)
        
        let products: [Product] = try productsCollection.map { productObject in
            let identifier = try requiredValue(for: "Identifier", in: productObject, ofType: String.self)
            let kindIdentifier = try requiredValue(for: "Kind", in: productObject, ofType: String.self)
            
            let kind: Product.Kind
            
            switch kindIdentifier {
                case "NonConsumable":
                    kind = .nonConsumable
                case "Consumable":
                    kind = .consumable
                case "Subscription":
                    let automaticallyRenews = try requiredValue(for: "Automatically Renews", in: productObject, ofType: Bool.self)
                    kind = .subscription(automaticallyRenews: automaticallyRenews)
                default:
                    throw Error.invalidValue(forKey: "Kind", reason: "\(kindIdentifier) not recognized as a product kind")
            }
            
            return Product(identifier: identifier, kind: kind)
        }
        
        self.products = Set(products)
        
        self.userInfo = object["User Info"] as? [String : Any] ?? [:]
    }
    
    public func product(withIdentifier identifier: String) -> Product? {
        return self.products.first(where: { candidate in
            candidate.identifier == identifier
        })
    }
    
    public enum Error : Swift.Error {
        case resourceNotFound
        case invalidResourceFormat
        case missingKey(String)
        case incorrectType(forKey: String, expected: Any.Type)
        case invalidValue(forKey: String, reason: String)
    }
}

private func requiredValue<T>(for key: String, in dict: [String : Any], ofType type: T.Type) throws -> T {
    guard let value = dict[key] else { throw LocalConfiguration.Error.missingKey(key) }
    guard let typedValue = value as? T else { throw LocalConfiguration.Error.incorrectType(forKey: key, expected: type) }
    
    return typedValue
}
