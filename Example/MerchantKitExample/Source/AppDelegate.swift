import UIKit
import MerchantKit

@UIApplicationMain
public class AppDelegate: UIResponder, UIApplicationDelegate {
    public var window: UIWindow?

    // A `Merchant` should be stored across the lifetime of the application.
    private var merchant: Merchant!
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Create a `Merchant` with a storage and a delegate.
        // For the demo, we are using ephemeral storage. The recommended storage for real apps is `KeychainPurchaseStorage`, or you can supply your own instance that conforms to the `PurchaseStorage` protocol.
        self.merchant = Merchant(storage: EphemeralPurchaseStorage(), delegate: self)
        
        // Register products with the `Merchant`. This could be supplied in code, like this demo, or from a resource file — see `LocalConfiguration`.
        self.merchant.register(ProductDatabase.allProducts)
        
        // Ensure to call `Merchant.setup()` during app launch to allow `Merchant` to begin observing `StoreKit` transactions.
        self.merchant.setup()
        
        // Create a view controller to display purchases. In this example, we are displaying all products in the `ProductDatabase`.
        let purchaseProductsViewController = PurchaseProductsViewController(presenting: ProductDatabase.allProducts, using: self.merchant)
        
        // Present the view controller in a navigation controller to make the UI look slightly better.
        let navigationController = UINavigationController(rootViewController: purchaseProductsViewController)
        
        // Storyboards are for suckers.
        self.window = {
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = navigationController
            
            window.makeKeyAndVisible()
            
            return window
        }()
        
        return true
    }
}

extension AppDelegate : MerchantDelegate {
    // The delegate is notified when the states of products change.
    // Use this to update app-global model data or perform custom logging, if appropriate.
    // For this example, we do nothing.
    public func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>) {
        
    }
    
    // Validate the given receipt request, calling the completion handler when done.
    // You can provide your own custom validation or use one of the validators provided as part of `MerchantKit`.
    // `LocalReceiptValidator` supports all types of purchases, including subscriptions, purely using on-device inspection of the receipt data.
    // The `LocalReceiptValidator` is a great way to get up and running, albeit offering few protections against piracy. In general, anti-piracy on iOS is not worth worrying about though.
    // The flexibility provided here is worth exploring. In sandbox/testing environments, you could validate all purchases as purchased, for example.
    public func merchant(_ merchant: Merchant, validate request: ReceiptValidationRequest, completion: @escaping (Result<Receipt>) -> Void) {
        let validator = LocalReceiptValidator(request: request)
        validator.onCompletion = { result in
            completion(result)
        }
        
        validator.start()
    }
}
