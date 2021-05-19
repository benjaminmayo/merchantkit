import UIKit
import MerchantKit

@UIApplicationMain
public class AppDelegate: UIResponder, UIApplicationDelegate {
    public var window: UIWindow?

    // A `Merchant` should be stored across the lifetime of the application.
    private var merchant: Merchant!
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Create a `Merchant` with a configuration and an optional delegate.
        // The configuration contains a validator and storage. The `Merchant.Configuration.default` configuration is appropriate for most applications and typically will not need to be customized. The `default` configuration validates receipts on device and stores state into the Keychain.
        // `MerchantKit` provides an alternative built-in configuration called `usefulForTestingAsPurchasedStateResetsOnApplicationLaunch`. This uses ephemeral storage so you can repeat product purchase flows just by quitting and relaunching the application. This is useful for testing but should never be used in production.
        // If you want to do something more intricate, you can create your own `Merchant.Configuration`.
        self.merchant = Merchant(configuration: .default, delegate: self)
        
        // Register products with the `Merchant`. This could be supplied in code, like this demo, or from a resource file — see `LocalConfiguration`.
        self.merchant.register(ProductDatabase.allProducts)
        
        // Ensure to call `Merchant.setup()` during app launch to allow `Merchant` to begin observing `StoreKit` transactions.
        self.merchant.setup()
        
        // Create a view controller to display the list of examples to choose from.
        let exampleListViewController = ExampleListViewController(merchant: self.merchant)
        
        // Present the view controller in a navigation controller to make the UI look slightly better.
        let navigationController = UINavigationController(rootViewController: exampleListViewController)
        
        // Display the window.
        self.window = {
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = navigationController
            
            window.makeKeyAndVisible()
            
            return window
        }()
        
        return true
    }
}

// Implement the required `MerchantDelegate` methods.
extension AppDelegate : MerchantDelegate {
    // The delegate is notified when the states of products change.
    // Use this to update app-global model data or perform custom logging, if appropriate.
    // For this example, we do nothing.
    public func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>) {
        
    }
    
    // The delegate is notified when the `isLoading` property of the `Merchant` changes.
    // You could adjust some global interface element here, or simply do nothing, if appropriate.
    // For this example, we toggle the `UIApplication.shared.isNetworkActivityIndicatorVisible` property to show a loading indicator in the status bar.
    public func merchantDidChangeLoadingState(_ merchant: Merchant) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = merchant.isLoading
    }
}
