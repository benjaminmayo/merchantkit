import UIKit
import MerchantKit

// This view controller demos different configurations of price formatters included with `MerchantKit`.
// Run the app and tweak the settings to get a sense of the flexibility.
// This view controller includes several shortcuts for sake of brevity and simplicity, and does not represent the best way to write a 'form' table view controller.
public final class PriceFormatterDemoViewController : UIViewController {
    // Model
    private var viewModel = ViewModel() {
        didSet {
            self.didChangeViewModel(from: oldValue)
        }
    }
    
    // Formatters
    private let priceFormatter = PriceFormatter()
    private let subscriptionPriceFormatter = SubscriptionPriceFormatter()
    
    // User Interface
    private let tableView = UITableView(frame: .zero, style: .grouped)
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewModel = ViewModel()
        
        self.priceFormatter.freeReplacementText = "Free"
        self.subscriptionPriceFormatter.freePriceReplacementText = "Free"
        
        self.title = "Price Formatters"

        self.view.backgroundColor = .white
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.view.addSubview(self.tableView)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.tableView.frame = self.view.bounds
    }
    
    private struct ViewModel {
        private var sections = [Section]()
        private var enabledToggles = Set<ToggleableOption>()
        
        var price: Price {
            return Price(value: (self.priceValue, self.locale))
        }
        
        var duration: SubscriptionDuration {
            let period = SubscriptionPeriod(unit: self.subscriptionPeriodUnit, unitCount: self.subscriptionPeriodUnitCount)
            let isRecurring = self.enabledToggles.contains(.isAutomaticallyRenewing)
            
            return SubscriptionDuration(period: period, isRecurring: isRecurring)
        }
        
        private var priceValue: Decimal {
            if self.priceValueMultiplier > 0 {
                return Decimal(self.priceValueMultiplier) - Decimal(string: "0.01")!
            } else {
                return 0.0
            }
        }
        
        var priceValueMultiplier: Int = 5
        
        private var locale: Locale = .current
        
        var subscriptionPeriodUnitCount: Int = 1
        private var subscriptionPeriodUnit: SubscriptionPeriod.Unit = .month
        
        private(set) var phrasingStyle: SubscriptionPriceFormatter.PhrasingStyle = .formal
        private(set) var durationStyle: SubscriptionPriceFormatter.UnitCountStyle = .numeric
        
        init() {
            self.setEnabled(true, for: .isSubscription)
            self.setEnabled(true, for: .isAutomaticallyRenewing)
            
            self.updateSections()
        }
        
        private mutating func updateSections() {
            var sections = [Section]()
            
            let previewSection = Section(header: "Formatted Price", rows: [.formattedPricePreview])
            sections.append(previewSection)
        
            let priceSection: Section = {
                var rows = [Row]()
                
                rows.append(.numeric(.priceValue))
                rows.append(.toggle(.isSubscription))
                
                return Section(header: "", rows: rows)
            }()
            
            sections.append(priceSection)
            
            if self.isEnabled(for: .isSubscription) {
                var rows = [Row]()
                rows.append(.numeric(.subscriptionPeriodUnitCount))
                rows.append(.multipleChoice(.subscriptionPeriodUnit))
                rows.append(.toggle(.isAutomaticallyRenewing))
                
                let section = Section(header: "", rows: rows)
            
                sections.append(section)
            }
            
            if self.isEnabled(for: .isSubscription) {
                var rows = [Row]()

                rows.append(.multipleChoice(.phrasing))
                rows.append(.multipleChoice(.durationStyle))
            
                let section = Section(header: "", rows: rows)
                sections.append(section)
            }
            
            self.sections = sections
        }
        
        var numberOfSections: Int {
            return self.sections.count
        }
        
        func numberOfRows(inSection section: Int) -> Int {
            return self.sections[section].rows.count
        }
        
        func header(forSection section: Int) -> String {
            return self.sections[section].header
        }
        
        func row(at indexPath: IndexPath) -> Row {
            return self.sections[indexPath.section].rows[indexPath.row]
        }
        
        func indexPath(for row: Row) -> IndexPath? {
            for sectionIndex in 0..<self.numberOfSections {
                for rowIndex in 0..<self.numberOfRows(inSection: sectionIndex) {
                    let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
                    
                    if self.row(at: indexPath) == row {
                        return indexPath
                    }
                }
            }
            
            return nil
        }
        
        func isTableLayoutSame(as other: ViewModel) -> Bool {
            return self.sections == other.sections
        }
        
        func isEnabled(for option: ToggleableOption) -> Bool {
            return self.enabledToggles.contains(option)
        }
        
        func stepperValues(for option: NumericOption) -> (current: Int, min: Int, max: Int) {
            switch option {
                case .priceValue:
                    return (self.priceValueMultiplier, 0, 100)
                case .subscriptionPeriodUnitCount:
                    return (self.subscriptionPeriodUnitCount, 1, 30)
            }
        }
        
        func values(for option: MultipleChoiceOption) -> MultipleChoices {
            switch option {
                case .subscriptionPeriodUnit:
                    return self.multipleChoices(for: self.possibleSubscriptionPeriodUnitValues, storedValue: self.subscriptionPeriodUnit)
                case .phrasing:
                    return self.multipleChoices(for: self.possiblePhrasingStyleValues, storedValue: self.phrasingStyle)
                case .durationStyle:
                    return self.multipleChoices(for: self.possibleDurationStyleValues, storedValue: self.durationStyle)
            }
        }
        
        mutating func setSelectedValueIndex(_ index: Int, for option: MultipleChoiceOption) {
            switch option {
                case .subscriptionPeriodUnit:
                    self.subscriptionPeriodUnit = self.possibleSubscriptionPeriodUnitValues[index].0
                case .phrasing:
                    self.phrasingStyle = self.possiblePhrasingStyleValues[index].0
                case .durationStyle:
                    self.durationStyle = self.possibleDurationStyleValues[index].0
            }
        }
        
        mutating func setEnabled(_ enabled: Bool, for option: ToggleableOption) {
            if enabled {
                self.enabledToggles.insert(option)
            } else {
                self.enabledToggles.remove(option)
            }
            
            self.updateSections()
        }
        
        private let possibleSubscriptionPeriodUnitValues: [(SubscriptionPeriod.Unit, String)] = [(.day, "Day"), (.week, "Week"), (.month, "Month"), (.year, "Year")]
        private let possiblePhrasingStyleValues: [(SubscriptionPriceFormatter.PhrasingStyle, String)] = [(.formal, "Formal"), (.informal, "Informal")]
        private let possibleDurationStyleValues: [(SubscriptionPriceFormatter.UnitCountStyle, String)] = [(.numeric, "Numeric"), (.spellOut, "Spell Out")]
        
        private func multipleChoices<Value>(for values: [(Value, String)], storedValue: Value) -> MultipleChoices where Value : Equatable {
            let selectedIndex = values.firstIndex(where: {
                $0.0 == storedValue
            })!
            
            return MultipleChoices(labels: values.map {
                $0.1
            }, selectedIndex: selectedIndex)
        }
        
        private struct Section : Equatable {
            let header: String
            let rows: [Row]
            
            init(header: String, rows: [Row]) {
                self.header = header
                self.rows = rows
            }
        }
    }
    
    private enum ToggleableOption : Hashable {
        case isSubscription
        case isAutomaticallyRenewing
        
        var label: String {
            switch self {
                case .isSubscription:
                    return "Offers Subscription"
                case .isAutomaticallyRenewing:
                    return "Automatically Renews"
            }
        }
    }
    
    private enum MultipleChoiceOption : Equatable {
        case subscriptionPeriodUnit
        case phrasing
        case durationStyle
        
        var label: String {
            switch self {
                case .subscriptionPeriodUnit:
                    return ""
                case .phrasing:
                    return "Preferred Phrasing"
                case .durationStyle:
                    return "Duration Style"
            }
        }
    }
    
    private enum NumericOption {
        case priceValue
        case subscriptionPeriodUnitCount
    }
    
    struct MultipleChoices {
        let labels: [String]
        let selectedIndex: Int
        
        init(labels: [String], selectedIndex: Int) {
            self.selectedIndex = selectedIndex
            self.labels = labels
        }
    }
    
    private enum Row : Equatable {
        case formattedPricePreview
        case toggle(ToggleableOption)
        case multipleChoice(MultipleChoiceOption)
        case numeric(NumericOption)
    }
}

extension PriceFormatterDemoViewController {
    private func updateFormattedPriceLabel(animated: Bool) {
        if let indexPath = self.viewModel.indexPath(for: .formattedPricePreview), let cell = self.tableView.cellForRow(at: indexPath) as? PreviewLabelTableViewCell {
            let previewText = self.previewTextForFormattedPrice()
            cell.setPreviewText(previewText, animated: animated)
        }
    }
    
    private func updateNumericCell(_ cell: UITableViewCell, for option: NumericOption) {
        switch option {
            case .priceValue:
                cell.textLabel!.text = "Value: \(self.viewModel.price.value.number)"
            case .subscriptionPeriodUnitCount:
                cell.textLabel!.text = "Period Units: \(self.viewModel.subscriptionPeriodUnitCount)"
        }
    }
    
    private func previewTextForFormattedPrice() -> String {
        if self.viewModel.isEnabled(for: .isSubscription) {
            self.subscriptionPriceFormatter.phrasingStyle = self.viewModel.phrasingStyle
            self.subscriptionPriceFormatter.unitCountStyle = self.viewModel.durationStyle
            
            let formattedPrice = self.subscriptionPriceFormatter.string(from: self.viewModel.price, duration: self.viewModel.duration)
            
            return formattedPrice
        } else {
            let formattedPrice = self.priceFormatter.string(from: self.viewModel.price)
            
            return formattedPrice
        }
    }
    
    private func didChangeViewModel(from oldViewModel: ViewModel) {
        self.updateFormattedPriceLabel(animated: true)
        
        if !self.viewModel.isTableLayoutSame(as: oldViewModel) {
            self.tableView.reloadData()
        }
    }
}

extension PriceFormatterDemoViewController : UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.numberOfSections
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfRows(inSection: section)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = self.viewModel.row(at: indexPath)
        
        switch row {
            case .formattedPricePreview:
                let cell = PreviewLabelTableViewCell()
                cell.setPreviewText(self.previewTextForFormattedPrice(), animated: false)
                
                return cell
            case .numeric(let option):
                let stepperValues = self.viewModel.stepperValues(for: option)
                
                let stepper = UIStepper(frame: .zero)
                stepper.value = Double(stepperValues.current)
                stepper.minimumValue = Double(stepperValues.min)
                stepper.maximumValue = Double(stepperValues.max)
                stepper.stepValue = 1
                stepper.addTarget(self, action: #selector(self.didPressStepper(_:)), for: .valueChanged)

                let cell = UITableViewCell()
                
                self.updateNumericCell(cell, for: option)
                
                cell.accessoryView = stepper
            
                return cell
            case .toggle(let option):
                let toggleSwitch = UISwitch(frame: .zero)
                toggleSwitch.isOn = self.viewModel.isEnabled(for: option)
                toggleSwitch.addTarget(self, action: #selector(self.didToggleSwitch(_:)), for: .valueChanged)
                
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel!.text = option.label
                cell.accessoryView = toggleSwitch
                cell.selectionStyle = .none
                
                return cell
            case .multipleChoice(let option):
                let values = self.viewModel.values(for: option)
                
                let segmentedControl = UISegmentedControl(items: values.labels)
                segmentedControl.selectedSegmentIndex = values.selectedIndex
                segmentedControl.addTarget(self, action: #selector(self.didChangeSegmentedControl(_:)), for: .valueChanged)

                if option.label.isEmpty {
                    let segmentedControlSize = segmentedControl.sizeThatFits(.zero)
                    
                    segmentedControl.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.width - self.tableView.layoutMargins.left - self.tableView.layoutMargins.right, height: segmentedControlSize.height)
                }
                
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel!.text = option.label
                cell.accessoryView = segmentedControl
                cell.selectionStyle = .none

                return cell
        }
    }
}

extension PriceFormatterDemoViewController : UITableViewDelegate {
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.viewModel.header(forSection: section)
    }
}

extension PriceFormatterDemoViewController {
    @objc private func didToggleSwitch(_ sender: UISwitch) {
        let cell = sender.superview as! UITableViewCell
        guard let indexPath = self.tableView.indexPath(for: cell) else { return }
        
        let row = self.viewModel.row(at: indexPath)
        
        switch row {
            case .toggle(let option):
                // delay view model updates until after the switch animation completes
                // a real app would use a fine-grained diffing/update mechanism, not this timing hack
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.viewModel.setEnabled(sender.isOn, for: option)
                })
            default:
                fatalError("logic error")
        }
    }
    
    @objc private func didChangeSegmentedControl(_ sender: UISegmentedControl) {
        let cell = sender.superview as! UITableViewCell
        guard let indexPath = self.tableView.indexPath(for: cell) else { return }
        
        let row = self.viewModel.row(at: indexPath)

        switch row {
            case .multipleChoice(let option):
                self.viewModel.setSelectedValueIndex(sender.selectedSegmentIndex, for: option)
            default:
                fatalError("logic error")
        }
    }
    
    @objc private func didPressStepper(_ sender: UIStepper) {
        let cell = sender.superview as! UITableViewCell
        guard let indexPath = self.tableView.indexPath(for: cell) else { return }

        let row = self.viewModel.row(at: indexPath)

        switch row {
            case .numeric(let option):
                switch option {
                    case .priceValue:
                        self.viewModel.priceValueMultiplier = Int(sender.value)
                    case .subscriptionPeriodUnitCount:
                        self.viewModel.subscriptionPeriodUnitCount = Int(sender.value)
                }
                
                self.updateNumericCell(cell, for: option)
            default:
                fatalError("logic error")
        }
    }
}

private class PreviewLabelTableViewCell : UITableViewCell {
    private var previewText: String {
        get {
            return self.label.text ?? ""
        }
        set {
            self.label.text = newValue
        }
    }
    private let label = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.separatorInset = .zero
        
        self.label.text = "oiamdoiasdm "
        self.label.font = UIFont.preferredFont(forTextStyle: .title1)
        self.label.adjustsFontSizeToFitWidth = true
        self.label.minimumScaleFactor = 0.5
        self.label.textAlignment = .center

        self.contentView.addSubview(self.label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var labelSize = self.label.sizeThatFits(size)
        labelSize.height += 50
        
        return labelSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.frame = self.contentView.bounds
    }
    
    func setPreviewText(_ previewText: String, animated: Bool) {
        guard self.previewText != previewText else { return }
        
        if animated {
            self.label.alpha = 0
            self.previewText = previewText
            
            UIView.animate(withDuration: 0.4, animations: {
                self.label.alpha = 1
            })
        } else {
            self.previewText = previewText
        }
    }
}
