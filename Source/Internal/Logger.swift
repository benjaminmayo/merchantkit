import os.log

internal class Logger {
    internal var isActive: Bool = false
    
    internal let loggingSubsystem: String = {
        return [Bundle.main.bundleIdentifier, "MerchantKit"].compactMap { $0 }.joined(separator: ".")
    }()
    
    internal init() {
        
    }
    
    internal func log(message: @autoclosure () -> String, category: Category, type: OSLogType = .debug) {
        guard self.isActive else { return }
        
        let storage = self.logStorage(for: category)
        
        if storage.isEnabled(type: type) {
            os_log("%{public}@", log: storage, type: type, message())
        }
    }
    
    internal enum Category {
        case initialization
        case tasks
        case receipt
        case purchaseStorage
        case storeInterface
        
        fileprivate var stringValue: String {
            switch self {
                case .initialization:
                    return "Initialization"
                case .tasks:
                    return "Tasks"
                case .receipt:
                    return "Receipt"
                case .purchaseStorage:
                    return "Purchase Storage"
                case .storeInterface:
                    return "Store Interface"
            }
        }
    }
}

extension Logger {
    private func logStorage(for category: Category) -> OSLog {
        return OSLog(subsystem: self.loggingSubsystem, category: category.stringValue)
    }
}
