import UIKit
import MerchantKit

public class PurchaseProductsViewController : UIViewController {
    // Model
    private let productInterfaceController: ProductInterfaceController
    private var tableSections = [Section]()
    
    // Formatters
    private let priceFormatter = PriceFormatter()
    
    // User Interface
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let actionTintColor = UIColor(red: 0/255.0, green: 122/255.0, blue: 255/255.0, alpha: 1.0)
    
    public init(merchant: Merchant, displayingProducts products: [Product]) {
        self.productInterfaceController = ProductInterfaceController(products: Set(products), with: merchant)
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
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Products"
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.view.addSubview(self.tableView)
        
        self.productInterfaceController.delegate = self
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.productInterfaceController.fetchDataIfNecessary()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.tableView.frame = self.view.bounds
    }
    
    private enum Section { // a very feeble data model for this view controller
        case introduction(Row)
        case products([Row])
        case actions([Row])
        
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
        
//        func index(of row: Row) -> Int? {
//            for index in 0..<self.rowCount {
//                if self.row(at: index) == row {
//                    return index
//                }
//            }
//
//            return nil
//        }
    }
    
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
        self.tableView.reloadData()
    }
    
    public func productInterfaceController(_ controller: ProductInterfaceController, didCommit purchase: Purchase, with result: ProductInterfaceController.CommitPurchaseResult) {
        if let indexPath = self.indexPath(ofRowForProductWithIdentifier: purchase.productIdentifier) {
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
        
        switch result {
            case .succeeded, .failed(_, shouldDisplayError: false):
                break
            
            case .failed(let error, shouldDisplayError: true):
                self.presentError(title: "Failed To Purchase", message: error.localizedDescription)
        }
    }
    
    public func productInterfaceController(_ controller: ProductInterfaceController, didRestorePurchasesWith result: ProductInterfaceController.RestorePurchasesResult) {
        if let indexPath = self.indexPath(of: .action(.restorePurchases)) {
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
        
        switch result {
            case .succeeded(_):
                break
            case .failed(let error):
                self.presentError(title: "Failed To Restore Purchases", message: error.localizedDescription)
        }
    }
}

extension PurchaseProductsViewController : UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.tableSections.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection sectionIndex: Int) -> Int {
        return self.section(at: sectionIndex).rowCount
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.row(at: indexPath) {
            case .product(let product):
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
                
                let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
                cell.textLabel?.text = title
                cell.detailTextLabel?.text = detailText
                cell.accessoryView = accessoryView
                
                return cell
            case .action(let action):
                let actionName: String
            
                switch action {
                    case .restorePurchases:
                        actionName = "Restore Purchases"
                }
            
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = actionName
                cell.textLabel?.textColor = self.actionTintColor
                
                return cell
            case .text(let text):
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = text
                cell.textLabel?.numberOfLines = 0
                
                return cell
        }
    }
}

extension PurchaseProductsViewController : UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
        switch (self.section(at: sectionIndex), self.productInterfaceController.fetchingState) {
            case (.products(_), .failed(let reason)):
                switch reason {
                    case .storeKitFailure(let error):
                        return "There was an error communicating with the iTunes Store. (Error code: \(error.code.rawValue))"
                    case .networkFailure(let error):
                        return "There was an error connecting to the Internet. Check your network connectivity and try again later. (Error code: \(error.code.rawValue))"
                    case .genericProblem:
                        return "There was an error loading products. Try again later."
                }
            default:
                return nil
        }
    }
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
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

extension PurchaseProductsViewController {
    private func section(at index: Int) -> Section {
        return self.tableSections[index]
    }
    
    private func row(at indexPath: IndexPath) -> Row {
        return self.tableSections[indexPath.section].row(at: indexPath.row)
    }
    
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
    
    private func indexPath(of row: Row) -> IndexPath? {
        return self.indexPath(ofRowWhere: { candidate in
            candidate == row
        })
    }
    
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
    
    private func presentError(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alertController, animated: true)
    }
    
    // presents a 'global' loading indicator, that is independent from the loading indicator when purchasing a specific product
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
}
