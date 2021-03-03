import UIKit
import MerchantKit

public class PurchaseProductsViewController : UIViewController {
    // Model
    private let productInterfaceController: ProductInterfaceController
    private let tableSections: [Section]
    
    // Formatters
    private let priceFormatter = PriceFormatter() // if presenting subscription purchases, see `SubscriptionPriceFormatter`.
    
    // User Interface
    private let tableView = UITableView(frame: .zero, style: .grouped)
    
    // Instantiate a view controller that will display the provided `products` using the `Merchant`.
    // It is generally a good idea to use this kind of dependency injection pattern.
    public init(presenting products: [Product], using merchant: Merchant) {
        // Construct a `ProductInterfaceController`. As the controller intentionally stores its products as an unordered set, layout of products in the UI is the responsibility of the app interface.
        // The design of the `ProductInterfaceController` is flexible enough to support many types of user interfaces, with one or more products at a time. A view controller is the obvious example case.
        self.productInterfaceController = ProductInterfaceController(products: Set(products), with: merchant)
        // Construct a basic view model for the view controller to display. This is obviously a rudimentary data structure, for the sake of a simplified demo.
        self.tableSections = [
            .introduction(.text("This is a (very ugly) purchase product storefront, demonstrating the usage of ProductInterfaceController to display and buy products. Products. Products. Products.\n\nNote that you will encounter various errors when running this project as StoreKit will expect products to be registered in App Store Connect. Hopefully, the source code sufficiently describes the general flow so it can aid implementation of MerchantKit into real projects.")),
            .products(products.map { .product($0) }),
            .actions([.action(.restorePurchases)])
        ]
        
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Setup the view controller.
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Products"
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.view.addSubview(self.tableView)
        
        // Become the `delegate` of the `ProductInterfaceController` to receive updates.
        self.productInterfaceController.delegate = self
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Fetch initial data for the `ProductInterfaceController`. This method can be called repeatedly but will only refresh data when needed, preserving network bandwidth.
        // Fetching changes are indicated by a loading indicator in the navigation bar for this demo.
        // Note that we do not need to cover the entire UI with a full-screen loading placeholder view, as we have enough data like the names of products to show something meaningful right away.
        // Per-product purchase information is gracefully displayed when the fetch completes.
        self.productInterfaceController.fetchDataIfNecessary()
    }
    
    // Make the `tableView` fill the view controller.
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.tableView.frame = self.view.bounds
    }
    
    // A very feeble data model structure to represent the content of the table in this view controller.
    private enum Section {
        // A simple section that contains a textual description.
        case introduction(Row)
        // A section that displays one or more products.
        case products([Row])
        // A section that displays one or more action buttons.
        case actions([Row])
        
        // The number of rows in the given section.
        var rowCount: Int {
            switch self {
                case .introduction(_):
                    return 1
                case .products(let products):
                    return products.count
                case .actions(let actions):
                    return actions.count
            }
        }
        
        // The row at the given index in the section.
        func row(at index: Int) -> Row {
            switch self {
                case .introduction(let row):
                    return row
                case .products(let products):
                    return products[index]
                case .actions(let actions):
                    return actions[index]
            }
        }
    }
    
    
    // For this example, we have simple text, product listing and action button cell types.
    // In more sophisticated user interfaces, it may make sense to include the `ProductInterfaceController.ProductState` in the view model itself.
    private enum Row : Equatable {
        case text(String)
        case product(Product)
        case action(Action)
        
        enum Action {
            case restorePurchases
        }
    }
}

extension PurchaseProductsViewController : ProductInterfaceControllerDelegate {
    public func productInterfaceControllerDidChangeFetchingState(_ controller: ProductInterfaceController) {
        // Toggle the presentation of the loading indicator in the navigation bar, responding to changes in `ProductInterfaceController.fetchingState`.
        // Call `self.tableView.reloadData()` because our table section footer (as seen in `UITableViewDataSource.tableView(_:titleForFooterInSection:)`) depends on the `ProductInterfaceController.fetchingState`, and `UITableView` does not offer a way to only reload the footer of a section.

        let isVisible: Bool
        
        switch controller.fetchingState {
            case .loading:
                isVisible = true
            default:
                isVisible = false
        }
        
        self.updateFetchingIndicator(isVisible: isVisible)
        self.tableView.reloadData()
    }
    
    public func productInterfaceController(_ controller: ProductInterfaceController, didChangeStatesFor products: Set<Product>) {
        // The table depends on the state of products to render its interface. Therefore, we update the table when we are notified that the state of a product changes.
        // This implementation could be as simple as `self.tableView.reloadData()`.
        // For the demo, we update the specific cells corresponding to each changed product state.
        
        for product in products {
            guard
                let indexPath = self.indexPath(ofRowForProductWithIdentifier: product.identifier),
                let cell = self.tableView.cellForRow(at: indexPath)
            else { continue }

            self.configureCell(cell, for: product)
        }
    }
    
    public func productInterfaceController(_ controller: ProductInterfaceController, didCommit purchase: Purchase, with result: ProductInterfaceController.CommitPurchaseResult) {
        // This delegate method is invoked as a result of invoking `ProductInterfaceController.commit(_:)`.
        // As our `tableView(_:didSelectRowAt:)` implementation does not immediately deselect a row when purchasing, we need to do that here.
        // If there was an error, we want to tell the user the purchase failed. `shouldDisplayUser` indicates if an error is relevant for presentation.
        
        if let indexPath = self.indexPath(ofRowForProductWithIdentifier: purchase.productIdentifier) {
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
        
        switch result {
            case .failure(let error) where error.shouldDisplayInUserInterface:
                self.presentError(title: "Failed To Purchase", message: error.localizedDescription)
            default:
                break
        }
    }
    
    public func productInterfaceController(_ controller: ProductInterfaceController, didRestorePurchasesWith result: ProductInterfaceController.RestorePurchasesResult) {
        // This delegate method is invoked as a result of invoking `ProductInterfaceController.restorePurchases()`.
        // As our `tableView(_:didSelectRowAt:)` implementation does not immediately deselect a row when the action is pressed, we need to do that here.
        // If there was an error, we display that to the user.
        
        if let indexPath = self.indexPath(of: .action(.restorePurchases)) {
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
        
        switch result {
            case .success(_):
                break
            case .failure(let error):
                self.presentError(title: "Failed To Restore Purchases", message: error.localizedDescription)
        }
    }
}

extension PurchaseProductsViewController : UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        // Feed the data source.
        
        return self.tableSections.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection sectionIndex: Int) -> Int {
        // Feed the data source.
        
        return self.section(at: sectionIndex).rowCount
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Provide cells for each row in the table.
        // A real app would use much nicer UI components than these basic tweaks to default `UITableViewCell` styles.
        // Cell dequeue is also omitted for simplicity of the demo.
        
        switch self.row(at: indexPath) {
            case .product(let product):
                let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
                
                self.configureCell(cell, for: product) // product cell configuration
                
                return cell
            case .action(let action):
                let actionName: String
            
                switch action {
                    case .restorePurchases:
                        actionName = "Restore Purchases"
                }
            
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel!.text = actionName
                cell.textLabel!.textColor = self.actionTintColor
                
                return cell
            case .text(let text):
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel!.text = text
                cell.textLabel!.numberOfLines = 0
                
                return cell
        }
    }

    // Display information about the state of the `product` in the cell.
    // We are assuming that this view controller specifies that it only manages products available in the `ProductDatabase`. This requirement could have been relaxed if the view controller was informed about product names in a more general way.
    private func configureCell(_ cell: UITableViewCell, for product: Product) {
        let productState = self.productInterfaceController.state(for: product)
        let productName = ProductDatabase.localizedDisplayName(for: product)
        
        let title: String
        let detailText: String
        let accessoryView: UIView?
        
        switch productState {
            case .purchasable(let purchase):
                title = productName
                detailText = self.priceFormatter.string(from: purchase.price)
                accessoryView = nil
            case .purchased(_, _):
                title = productName
                detailText = "Purchased"
                accessoryView = nil
            case .purchaseUnavailable:
                title = "\(productName)"
                detailText = "Purchase Unavailable"
                accessoryView = nil
            case .purchasing(_):
                let loadingIndicatorView = UIActivityIndicatorView(style: .gray)
                loadingIndicatorView.startAnimating()
                
                title = productName
                detailText = ""
                accessoryView = loadingIndicatorView
            case .unknown:
                title = productName
                detailText = "—"
                accessoryView = nil
        }
        
        cell.textLabel!.text = title
        cell.detailTextLabel!.text = detailText
        cell.accessoryView = accessoryView
    }
}

extension PurchaseProductsViewController : UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Determine what action to perform based on the selected cell.
        // If a product is tapped, we need to extract the `Purchase` from the `ProductState` and pass that to the `ProductInterfaceController.commit(_:)` method.
        // Note how this flow naturally prevents initiating purchases for products that have already been purchased.
        // If the restore purchases action is tapped, call `ProductInterfaceController.restorePurchases()`.
        
        switch self.row(at: indexPath) {
            case .product(let product):
                let state = self.productInterfaceController.state(for: product)
            
                switch state {
                    case .purchasable(let purchase):
                        self.productInterfaceController.commit(purchase)
                    default:
                        self.tableView.deselectRow(at: indexPath, animated: true)
                }
            case .action(.restorePurchases):
                self.productInterfaceController.restorePurchases()
            case .text(_):
                break
        }
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection sectionIndex: Int) -> String? {
        // Feed the delegate with some basic UI.
        
        switch self.section(at: sectionIndex) {
            case .introduction(_):
                return nil
            case .products(_):
                return "Buy Products"
            case .actions(_):
                return nil
        }
    }
    
    public func tableView(_ tableView: UITableView, titleForFooterInSection sectionIndex: Int) -> String? {
        // Feed the delegate with some basic UI.
        // Display fetching errors as a section footer, if there was an error.
        
        guard
            sectionIndex == self.indexOfSectionForFetchingErrorFooter(),
            case .failed(let reason) = self.productInterfaceController.fetchingState
        else { return nil }
        
        switch reason {
            case .storeKitFailure(let error):
                return "There was an error communicating with the iTunes Store. (Error code: \(error.code.rawValue))"
            case .networkFailure(let error):
                return "There was an error connecting to the Internet. Check your network connectivity and try again later. (Error code: \(error.code.rawValue))"
            case .genericProblem:
                return "There was an error loading products. Try again later."
            case .userNotAllowedToMakePurchases:
                return "There was an error. User is not allowed to make purchases."
        }
    }
    
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        // Some basic contextual interactions. Allow selection of all action button cells, never allow selection for text cells, and conditionally allow selection for product cells if they are purchasable.
        switch self.row(at: indexPath) {
            case .product(let product):
                let state = self.productInterfaceController.state(for: product)
            
                switch state {
                    case .purchasable(_):
                        return true
                    default:
                        return false
                }
            case .action(_):
                return true
            case .text(_):
                return false
        }
    }
}

// These utility methods are basically inconsequential to the `MerchantKit` example, but are needed to make the demo app work.
extension PurchaseProductsViewController {
    // Returns the section for the given index.
    private func section(at index: Int) -> Section {
        return self.tableSections[index]
    }
    
    // Returns the index of the section in which to display a fetching error in its footer.
    private func indexOfSectionForFetchingErrorFooter() -> Int {
        return self.tableSections.firstIndex(where: { section in
            switch section {
                case .products(_): return true
                default: return false
            }
        })!
    }
    
    // Returns the row for the given `IndexPath`.
    private func row(at indexPath: IndexPath) -> Row {
        return self.tableSections[indexPath.section].row(at: indexPath.row)
    }
    
    // Returns the `IndexPath` for the row that matches a `predicate`.
    private func indexPath(ofRowWhere predicate: (Row) -> Bool) -> IndexPath? {
        for (sectionIndex, section) in self.tableSections.enumerated() {
            for rowIndex in 0..<section.rowCount {
                let row = section.row(at: rowIndex)
                
                if predicate(row) {
                    return IndexPath(row: rowIndex, section: sectionIndex)
                }
            }
        }
        
        return nil
    }
    
    // Returns the `IndexPath` for the given `row`.
    private func indexPath(of row: Row) -> IndexPath? {
        return self.indexPath(ofRowWhere: { candidate in
            candidate == row
        })
    }
    
    // Returns the `IndexPath` for the given row which presents a `Product` with the given `productIdentifier`.
    private func indexPath(ofRowForProductWithIdentifier productIdentifier: String) -> IndexPath? {
        return self.indexPath(ofRowWhere: { row in
            switch row {
                case .product(let product) where product.identifier == productIdentifier:
                    return true
                default:
                    return false
            }
        })
    }
    
    // Presents a simple modal error dialog.
    private func presentError(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alertController, animated: true)
    }
    
    // Presents a 'global' loading indicator for the fetching state, separate from the loading indicators which are specific to a particular product.
    private func updateFetchingIndicator(isVisible: Bool) {
        if isVisible {
            let indicatorView = UIActivityIndicatorView(style: .gray)
            indicatorView.startAnimating()
            
            let barButtonItem = UIBarButtonItem(customView: indicatorView)
            
            self.navigationItem.rightBarButtonItem = barButtonItem
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    // A consistent tint color for the action button. This is needed because we aren't using proper `UITableViewCell` subclasses in the demo.
    private var actionTintColor: UIColor {
        return UIColor(red: 0/255.0, green: 122/255.0, blue: 255/255.0, alpha: 1.0)
    }
}
