import UIKit
import MerchantKit

@UIApplicationMain
public class AppDelegate: UIResponder, UIApplicationDelegate {
    public var window: UIWindow?

    private var merchant: Merchant!
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.merchant = Merchant(storage: EphemeralPurchaseStorage(), delegate: self)
        self.merchant.register(ProductDatabase.allProducts)
        self.merchant.setup()
        
        let purchaseProductsViewController = PurchaseProductsViewController(using: self.merchant, presenting: ProductDatabase.allProducts)
        let navigationController = UINavigationController(rootViewController: purchaseProductsViewController)
        
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
    public func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>) {
        
    }
    
    public func merchant(_ merchant: Merchant, validate request: ReceiptValidationRequest, completion: @escaping (Result<Receipt>) -> Void) {
        let validator = LocalReceiptValidator(request: request)
        validator.onCompletion = { result in
            completion(result)
        }
        
        validator.start()
    }
}
