# MerchantKit
A modern In-App Purchases management framework for iOS developers.

`MerchantKit` dramatically simplifies the work indie developers have to do in order to add premium monetizable components to their applications. Track purchased products, offer auto-renewing subscriptions, restore transactions, and much more.

Designed for apps that have a finite set of purchasable products, `MerchantKit` is a great way to add an unlockable 'pro tier' to an application, as a one-time purchase or ongoing subscription.

## Example Snippets

Find out if a product has been purchased:

```swift
let product = merchant.product(withIdentifier: "iap.productidentifier")
print("isPurchased: \(merchant.state(for: product).isPurchased))"
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
            case .isPurchased(let info):
                print("subscribed, expires \(info.expiryDate)")
            default:
                print("does not have active subscription")
        }
    }
}
```

## Project Goals

- Straightforward, concise, API to support non-consumable, consumable and subscription In-App Purchases.
- Simplify the development of In-App Purchase interfaces in apps, including localized formatters to dynamically create strings like "£2.99 per month" or "Seven Day Free Trial".
- No external dependencies beyond what Apple ships with iOS. The project links `Foundation`, `StoreKit`, `SystemConfiguration` and `os` for logging purposes. 
- Prioritise developer convenience and accessibility over security. `MerchantKit` users accept that some level of piracy is inevitable and not worth chasing.
- Permissive open source license.
- Compatibility with latest Swift version using idiomatic language constructs.

The codebase is in flux right now and the project does not guarantee API stability. `MerchantKit` is useful, it works, and will probably save you time. That being said, `MerchantKit` is by no means finished. The test suite is patchy.

## Installation

#### CocoaPods

To integrate  `MerchantKit` into your Xcode project using CocoaPods, specify it in your `Podfile`.
```
pod 'MerchantKit'
```

#### Carthage

To integrate  `MerchantKit` into your Xcode project using Carthage, specify it in your `Cartfile`.
```
github "benjaminmayo/merchantkit"
```

#### Manually

Compile the `MerchantKit` framework and embed it in your application. You can download the source code from Github and embed the Xcode project into your app, although you'll have to upgrade to the latest releases manually.

## Getting Started

1. In your app delegate, import `MerchantKit` create a `Merchant` instance in `application(_:, didFinishLaunchingWithOptions:)`. Supply a configuration (such as `Merchant.Configuration.default`) and a delegate.
```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    ...
    
    self.merchant = Merchant(configuration: .default, delegate: self)
    
    ...
}

```
2. Register products as soon as possible (typically within `application(_:, didFinishLaunchingWithOptions:)`). You may want to load `Product` structures from a file, or simply declaring them as constants in code. These constants can then be referred to statically later.  
```swift
let product = Product(identifier: "iap.productIdentifier", kind: .nonConsumable)
let otherProduct = Product(identifier: "iap.otherProductIdentifier", kind: .subscription(automaticallyRenews: true)) 
self.merchant.register([product, otherProduct])

```
3. Call `setup()` on the merchant instance before escaping the `application(_:, didFinishLaunchingWithOptions:)` method. This tells the merchant to start observing the payment queue.
```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    ...
    
    self.merchant = Merchant(configuration: .default, delegate: self)    
    self.merchant.register(...)
    self.merchant.setup()
    
    ...
}
```
4. Profit! Or something.

## Merchant Configuration

`Merchant` is initialized with a configuration object; an instance of `Merchant.Configuration`. The configuration controls how `Merchant` validates receipts and persist product state to storage.
Most applications can simply use `Merchant.Configuration.default` and get the result they expect. You can supply your own `Merchant.Configuration` if you want to do something more customized.

Tip: `MerchantKit` provides  `Merchant.Configuration.usefulForTestingAsPurchasedStateResetsOnApplicationLaunch` as a built-in configuration. This can be used to test purchase flows during development as the configuration does not persist purchase states to permanent storage.
You can repeatedly test 'buying' any `Product`, including non-consumables, simply by restarting the app. As indicated by its unwieldy name, you should not use this configuration in a released application.

## Merchant Delegate

The delegate implements the `MerchantDelegate` protocol. This delegate provides an opportunity to respond to events at an app-wide level. The `MerchantDelegate` protocol declares a handful of methods, but only one is required to be implemented.

```swift
func merchant(_ merchant: Merchant, didChangeStatesFor products: Set<Product>) {
    // Called when the purchased state of a `Product` changes.
    
    for product in products {
        print("updated \(product)")
    }
}
```

The delegate optionally receives loading state change events, and a customization point for handling Promoted In-App Purchase flows that were initiated externally by the App Store. Sensible default implementations are provided for these two methods.

## Product Interface Controller

The tasks vended by a `Merchant` give developers access to the core operations to fetch and purchase products with interfaces that reflect Swift idioms better than the current `StoreKit` offerings. Many apps will not need to directly instantiate tasks. `ProductInterfaceController` is the higher-level API offered by `MerchantKit` that covers the use case of many projects. In an iOS app, a view controller displaying an upgrade screen would be backed by a single `ProductInterfaceController` which encapsulated all necessary product and purchasing logic.  

The `ProductInterfaceController` class encompasses common behaviours needed to present In-App Purchase for sale. However, it remains abstract enough not be tied down to one specific user interface appearance or layout. 

Developers simply provide the list of products to display and tells the controller to fetch data. The `delegate` notifies the app when to update its custom UI. It handles loading data, intermittent network connectivity and in-flight changes to the availability and state of products.

See the [Example project](Example/) for a basic implementation of the `ProductInterfaceController`.

## Formatters 

`MerchantKit` includes several formatters to help developers display the cost of In-App Purchases to users. 

`PriceFormatter` is the simplest. Just give it a `Price` and it returns formatted strings like '£3.99' or '$5.99' in accordance with the store's regional locale. You can specify a custom string if the price is free.
`SubscriptionPriceFormatter` takes a `Price` and a `SubscriptionDuration`. Relevant `Purchase` objects exposes these values so you can simply pass them along the formatter. It generates strings like '$0.99 per month', '£9.99 every 2 weeks' and '$4.99 for 1 month' depending on the period and whether the subscription will automatically renew. 

In addition to the renewal duration, subscriptions can include free trials and other introductory offers. You can use a `SubscriptionPeriodFormatter` to format a text label in your application. If you change the free trial offer in iTunes Connect, the label will dynamically update to reflect the changed terms without requiring a new App Store binary. For example:
```swift
func subscriptionDetailsForDisplay() -> String? {
    guard let terms = purchase.subscriptionTerms, let introductoryOffer = terms.introductoryOffer else { return nil }
    
    let formatter = SubscriptionPeriodFormatter()
    
    switch introductoryOffer {
        case .freeTrial(let period): return "\(formatter.string(from: period)) Free Trial" // something like '7 Day Free Trial'
        default: ...
    }
}
```

`PriceFormatter` works in every locale supported by the App Store. `SubscriptionPriceFormatter` and `SubscriptionPeriodFormatter` are currently offered in a small subset of languages. Voluntary translations are welcomed.

See the [Example project](Example/) for a demo where you can experiment with various configuration options for  `PriceFormatter` and  `SubscriptionPriceFormatter`.

## Consumable Products

`Merchant` tracks the purchased state of non-consumable and subscription products. Consumable products are considered transitory purchases and not recorded beyond the initial time of purchase. Because of their special nature, they must be handled differently. Ensure you supply a `consumableHandler` when creating the Merchant. This can by any object that conforms to the `MerchantConsumableProductHandler` protocol. The protocol has a single required method:

```swift
func merchant(_ merchant: Merchant, consume product: Product, completion: @escaping () -> Void) {
    self.addCreditsToUserAccount(for: product, completion: completion) // application-specific handling 
}
```

The `Merchant` will always report a consumable product's state as `PurchasedState.notPurchased`. Forgetting to implement the delegate method will result in a runtime fatal error.

## To Be Completed (in no particular order)

- Increase the number of localizations for `SubscriptionPriceFormatter` and `SubscriptionPeriodFormatter`.
- Add extensive documentation with more examples in the Example project.
- Support downloadable content In-App Purchases.
- Probably a lot more stuff I haven't thought of yet.

## Credits

Developed and managed by [Benjamin Mayo](https://bzamayo.com), [@bzamayo](http://twitter.com/bzamayo) on Twitter.
