import XCTest
@testable import MerchantKit

class LoggerTests : XCTestCase {
    func testSubsystemName() {
        func evaluate() {
            let logger = Logger()
        
            let expectedSubsystem: String
            
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                expectedSubsystem = bundleIdentifier + ".MerchantKit"
            } else {
                 expectedSubsystem = "MerchantKit"
            }
            
            XCTAssertEqual(logger.loggingSubsystem, expectedSubsystem)
        }
        
        evaluate()
        
        let failingImplementationClosure: @convention(c) (_ obj: NSObject, Selector) -> String? = { _, _ in
            return nil
        }
        
        let originalSelector = #selector(getter: Bundle.bundleIdentifier)
        
        let originalImplementation = class_getMethodImplementation(Bundle.self, originalSelector)!
        let method = class_getInstanceMethod(Bundle.self, originalSelector)!
        
        let failingImplementation = unsafeBitCast(failingImplementationClosure, to: IMP.self)
        
        method_setImplementation(method, failingImplementation)
                
        evaluate()
        
        method_setImplementation(method, originalImplementation)
    }
}
