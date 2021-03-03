import Foundation

internal protocol AvailablePurchasesFetcher : AnyObject {
    func enqueueCompletion(_ completion: @escaping (Result<PurchaseSet, AvailablePurchasesFetcherError>) -> Void)
    func start()
    func cancel()
}

enum AvailablePurchasesFetcherError : Swift.Error, CustomNSError {
	case userNotAllowedToMakePurchases
	case noAvailablePurchases(invalidProducts: Set<Product>)
	case other(Error)
	
	static var errorDomain: String {
		return "AvailablePurchasesFetcherError"
	}
	
	var errorCode: Int {
		switch self {
			case .userNotAllowedToMakePurchases:
				return 101
			case .noAvailablePurchases(invalidProducts: _):
				return 102
			case .other(let error as NSError):
				return error.code
		}
	}
	
	var errorUserInfo: [String : Any] {
		var userInfo = [String : Any]()
		
		switch self {
			case .other(let error):
				userInfo[NSUnderlyingErrorKey] = error
			case .userNotAllowedToMakePurchases:
				userInfo[NSLocalizedFailureReasonErrorKey] = "The user is not allowed to make purchases."
			case .noAvailablePurchases(invalidProducts: _):
				userInfo[NSLocalizedFailureReasonErrorKey] = "There are no available purchases."
		}
		
		return userInfo
	}
}
