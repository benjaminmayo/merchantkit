import os.log

internal class Logger {
    internal var isActive: Bool = false
    
    fileprivate let loggingSubsystem: String = {
        let subsystem: String
        
        if let identifier = Bundle.main.bundleIdentifier {
            return "\(identifier).MerchantKit"
        } else {
            return "MerchantKit"
        }
    }()
    
    internal init() {
        
    }
    
    internal func log(message: @autoclosure() -> String, category: Category, type: OSLogType = .debug) {
        guard self.isActive else { return }
        
        let storage = self.logStorage(for: category)
        guard storage.isEnabled(type: type) else { return }
        
        os_log("%{public}@", log: storage, type: type, message())
    }
    
    internal enum Category {
        case receipt
        case purchaseStorage
        
        fileprivate var stringValue: String {
            switch self {
                case .receipt:
                    return "Receipt"
                case .purchaseStorage:
                    return "Purchase Storage"
            }
        }
    }
}

extension Logger {
    private func logStorage(for category: Category) -> OSLog {
        return OSLog(subsystem: self.loggingSubsystem, category: category.stringValue)
    }
}
