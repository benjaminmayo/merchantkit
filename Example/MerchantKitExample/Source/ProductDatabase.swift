import MerchantKit

public enum ProductDatabase {
    public static let one = Product(identifier: "product.one", kind: .nonConsumable)
    public static let another = Product(identifier: "product.another", kind: .nonConsumable)
    
    public static func localizedDisplayName(for product: Product) -> String {
        switch product {
            case ProductDatabase.one:
                return "A Product"
            case ProductDatabase.another:
                return "Another Product"
            default:
                fatalError("unknown productIdentifier")
        }
    }
}
