import Foundation

extension String {
    /// Capitalizes the first letter of the string.
    internal func sentenceCapitalized(with locale: Locale) -> String {
        guard !self.isEmpty else { return "" }
        
        var result = self
        result.replaceSubrange(result.startIndex...result.startIndex, with: String(result[result.startIndex]).uppercased(with: locale))
        
        return result
    }
    
    /// Returns `nil` if the string is zero length, else returns the string. This is used to flatten a fair few logical tests in the framework, typically related to Objective-C interoperability.
    internal var nonEmpty: String? {
        guard !self.isEmpty else { return nil }
        
        return self
    }
}
