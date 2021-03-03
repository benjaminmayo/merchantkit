import Foundation

internal enum MerchantKitFatalError {
    internal typealias FatalErrorHandler = () -> Void
    
    internal static var customHandler: FatalErrorHandler?
    
    /// This method is necessary in order to unit test code-paths that rely on fatal errors.
    /// This weird indirect override `MerchantKitFatalError.raise(_:)` thingy is hacky and not very elegant. I solicit suggestions on better ways to achieve this.
    internal static func raise(_ message: String, file: StaticString = #file, line: UInt = #line) -> Never {
        if let handler = MerchantKitFatalError.customHandler {
            handler()
            
            repeat {
                RunLoop.current.run()
            } while true
        }
        
        fatalError(message, file: file, line: line)
    }
}
