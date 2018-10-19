import UIKit
import MerchantKit

public class ExampleListViewController : UIViewController {
    // Model
    private let merchant: Merchant
    private let examples: [Example]

    // User Interface
    private let tableView = UITableView(frame: .zero, style: .grouped)

    // Instantiate a view controller that will display available examples. Stores a reference to a `Merchant` that can be passed on.
    public init(merchant: Merchant) {
        self.merchant = merchant
        self.examples = [.productStorefront]
        
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Setup the view controller.
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Examples"
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.view.addSubview(self.tableView)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Some basic UI niceties.
        for indexPath in self.tableView.indexPathsForSelectedRows ?? [] {
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // Make the `tableView` fill the view controller.
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.tableView.frame = self.view.bounds
    }
    
    // A simple view model representing different examples in the project
    private enum Example {
        case productStorefront
        
        var name: String {
            switch self {
                case .productStorefront:
                    return "Product Storefront"
            }
        }
        
        var summary: String {
            switch self {
                case .productStorefront:
                    return "Uses ProductInterfaceController to manage a storefront interface and purchase products."
            }
        }
    }
}

extension ExampleListViewController {
    private func detailViewController(for example: Example) -> UIViewController {
        switch example {
            case .productStorefront:
                // Create a view controller to display purchases.
                // In this example, we show all products in the `ProductDatabase`.
                let purchaseProductsViewController = PurchaseProductsViewController(presenting: ProductDatabase.allProducts, using: self.merchant)
                
                return purchaseProductsViewController
        }
    }
}

extension ExampleListViewController : UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        // Feed the data source.
        
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection sectionIndex: Int) -> Int {
        // Feed the data source.
        
        return self.examples.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Display a cell for each action.
        // Cell dequeue is also omitted for simplicity of the demo.

        let example = self.examples[indexPath.row]
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = example.name
        cell.detailTextLabel?.text = example.summary
        cell.detailTextLabel?.numberOfLines = 0
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
}

extension ExampleListViewController : UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Present the example based on the selected cell.

        let example = self.examples[indexPath.row]
        let detailViewController = self.detailViewController(for: example)
        
        self.navigationController?.pushViewController(detailViewController, animated: true)
    }
}
