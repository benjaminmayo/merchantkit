import Foundation

extension String {
    internal func sentenceCapitalized(with locale: Locale) -> String {
        guard !self.isEmpty else { return "" }
        
        var result = self
        result.replaceSubrange(result.startIndex...result.startIndex, with: String(result[result.startIndex]).uppercased(with: locale))
        
        return result
    }
}
