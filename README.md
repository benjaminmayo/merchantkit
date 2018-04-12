# MerchantKit (working but work-in-progress)
A modern In-App Purchases management framework for iOS developers.

MerchantKit dramatically simplifies the work indie developers have to do in order to add premium monetizable components to their applications. Track purchased products, retrieve purchases, manage subscription expiration dates, restore transactions, validate receipts, and more.

Designed for apps that have a finite set of purchasable products, MerchantKit is a great way to add an unlockable 'pro tier' to an application, as a one-time purchase or ongoing subscription.

## Example Snippets

Find out if a product has been purchased:

```swift
let product = merchant.product(withIdentifier: "iap.productidentifier")
print("isPurchased", merchant.state(for: product).isPurchased)
```

Buy a product:

```swift
let task = merchant.commitPurchaseTask(for: purchase)
task.onCompletion = { result in 
    switch result {
        case .succeeded(_):
            print("purchase completed")
        case .failed(let error):
            print("\(error)")
    }
}

task.start()
```

Get notified when a subscription expires:

```swift
public func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>) {
    if let subscriptionProduct = products.first(where: { $0.identifier == "subscription.protier" }) {
        let state = merchant.state(for: subscriptionProduct)
        
        switch state {
            case .isSubscribed(let expiryDate):
                print("subscribed, expires \(expiryDate)")
            default:
                print("does not have active subscription")
        }
    }
}
```

## Project Goals

- Straightforward, concise, API to support non-consumable, consumable and subscription In-App Purchases.
- No external dependencies beyond what Apple ships with iOS. Right now, the project links Foundation and StoreKit and requires CocoaPods for OpenSSL usage. Ideally, I would love to eliminate OpenSSL dependency completely. This requires investigation and would appreciate guidance here. 
- Prioritise developer convenience and accessibility over security. MerchantKit users accept that some level of piracy is inevitable and not worth chasing.
- Do-whatever-you-want open source license.
- Compatibility with latest Swift version using idiomatic language constructs.

The codebase is in flux right now. MerchantKit is by no means finished and there are major components that are in the project's scope but completely unimplemented (consumable products are not supported). The test suite is currently bare.

## Getting Started

1. Compile the MerchantKit framework and embed it in your application. There is currently one dependency on a `openssl` framework. Therefore, the easiest way to get up and running is to use Cocoapods; the spec includes an OpenSSL dependency for ease of use. Add `MerchantKit` to your project's Podfile and build.

2. In your app delegate, import `MerchantKit` create a `Merchant` instance in `application(_:, didFinishLaunchingWithOptions:)`. Supply a storage object (recommended: `KeychainPurchaseStorage`) and a delegate.
```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    self.merchant = Merchant(storage: KeychainPurchaseStorage(serviceName: "AppName"), delegate: self)    
}
```

3. Implement the two required methods in `MerchantDelegate` to validate receipt data and receive notifications when the `PurchasedState` changes for registered products.
```swift
func merchant(_ merchant: Merchant, didChangeStateFor products: Set<Product>) {
    for product in products {
        print("updated \(product)")
    }
 }
    
func merchant(_ merchant: Merchant, validate request: ReceiptValidationRequest, completion: @escaping (Result<Receipt>) -> Void) {
    let validator = LocalReceiptValidator(request: request)
    validator.onCompletion = { result in
        completion(result)
    }
        
    validator.start()
}
```
4. Register products as soon as possible (typically within `application(_:, didFinishLaunchingWithOptions:)`). You may want to load these products from a resource file. The included `LocalConfiguration` object provides a mechanism for this.
```swift
let config = try! MerchantKit.LocalConfiguration(fromResourceNamed: "MerchantConfig", extension: "plist")
self.merchant.register(config.products)

```
5. Call `setup()` on the merchant instance before escaping the `application(_:, didFinishLaunchingWithOptions:)` method. This tells the merchant to start observing the payment queue.
```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    self.merchant = Merchant(storage: KeychainPurchaseStorage(serviceName: "AppName"), delegate: self)    
    self.merchant.register(...)
    ...
    self.merchant.setup()
}
```
6. Profit! Or something.

## To Be Completed (in no particular order)

- Add tests to the bare test suite. MerchantKit components can be tested separately, including the validators and `PurchaseStorage` types.
- Implement consumable purchases. This will likely involve a special delegate callback to tell the application to update its quantities.
- Enhance the API of `PriceFormatter` to be a comprehensive formatter for product prices. This includes adding ways to express subscription periods (eg: '£3.99 per month').
- Extended documentation with example usage projects.
- Support downloadable content In-App Purchases.
- Probably a lot more stuff I haven't thought of yet.

## Credits

Developed and managed by Benjamin Mayo. [Follow me on Twitter](http://twitter.com/bzamayo).
