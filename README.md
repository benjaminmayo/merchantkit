# MerchantKit
A modern In-App Purchases management framework for iOS developers.

MerchantKit dramatically simplifies the work indie developers have to do in order to add premium monetizable components to their applications.

MerchantKit handles retrieving purchases, tracking purchased products, watching for renewal and expiration of subscriptions, restoring transactions, validating iTunes Store receipts, and more. 

MerchantKit is designed for apps that have a finite set of purchasable products (although it is flexible enough to work with other types of apps too). For example, MerchantKit is a great way to add an unlockable 'pro tier' to an application, as a one-time purchase or ongoing subscription.

## Hello World

Find out if a product has been purchased:

    let merchant = Merchant(storage: ..., delegate: self)
    print("isPurchased", merchant.state(forProductWithIdentifier: "MyProductIdentifier").isPurchased)
    
Buy a product:

    let task = merchant.commitPurchaseTask(for: purchase)
    task.start()

## Project Goals

- Straightforward, concise, API to support non-consumable, consumable and subscription In-App Purchases.
- No external dependencies beyond Foundation and StoreKit.
- Prioritise developer convenience and accessibility over security. MerchantKit should support secure anti-piracy methods where possible without compromising developer ease-of-use.
- Do-whatever-you-want open source license.
- Written for the most modern public Swift version using idiomatic language constructs.

The codebase is in flux right now. MerchantKit is by no means finished and there are major components that are in the project's scope but completely unimplemented (consumable products are not supported). 
