import Foundation

public protocol ReceiptValidator {
    var subscriptionRenewalLeeway: ReceiptValidatorSubscriptionRenewalLeeway { get }
    
    func validate(_ request: ReceiptValidationRequest, completion: @escaping (Result<Receipt, Error>) -> Void)
}

/// The leeway represents the additional amount of time to accept a subscription as active, even if the known renewal date has technically elapsed. This is required because the `StoreKit` framework does not fastidiously update the local receipt storage. The leeway gives the system time to refresh the local receipts without interrupting the experience of legitimate paying users interacting with your application.
public struct ReceiptValidatorSubscriptionRenewalLeeway : Equatable {
    /// The leeway expressed as a duration in seconds. This time interval must be non-negative.
    internal let allowedElapsedDuration: TimeInterval
    
    public init(allowedElapsedDuration: TimeInterval) {
        guard allowedElapsedDuration >= 0 else { MerchantKitFatalError.raise("`allowedElapsedDuration` must be non-negative.") }
        
        self.allowedElapsedDuration = allowedElapsedDuration
    }
    
    /// The default leeway represents the recommended period of time to deem subscription expiration accurate. The exact value may change over time. The current value is a 30 day time interval.
    public static var `default`: ReceiptValidatorSubscriptionRenewalLeeway {
        return ReceiptValidatorSubscriptionRenewalLeeway(allowedElapsedDuration: 60 * 60 * 24 * 30)
    }
}
