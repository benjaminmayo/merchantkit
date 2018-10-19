import MerchantKit

// Mock data source for available `Product`s in this demo app.
// Often, an app will not need anything more complicated than a simple provider like this.
// If your app uses a freemium business model, for example, your product model could vend `Product` instances alongside associated data about the upgrades to present in the user interface.
public enum ProductDatabase {
    public static let one = Product(identifier: "product.one", kind: .nonConsumable)
    public static let another = Product(identifier: "product.another", kind: .nonConsumable)
    
    // All of the possible products available in the app. This sequence will be passed to the `Merchant.register(...)` method.
    public static var allProducts: [Product] {
        return [ProductDatabase.one, ProductDatabase.another]
    }
    
    // Providing localized names without going to the server (using `Purchase.localizedTitle` or similar) means you can provide the names of products without requiring a network load.
    // This tactic is recommended, although you probably want a slightly more sophisticated method than this simple switch statement. Loading the names of a pro subscription could reside in a Localizable.strings resource, for example.
    public static func localizedDisplayName(for product: Product) -> String {
        switch product {
            case ProductDatabase.one:
                return "A Product"
            case ProductDatabase.another:
                return "Another Product"
            default:
                fatalError("unknown product, localized name not available")
        }
    }
}
