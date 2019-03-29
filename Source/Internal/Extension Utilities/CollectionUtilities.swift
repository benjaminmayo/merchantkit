import Foundation

extension Collection {
    /// Returns `nil` if the string is zero length, else returns the string. This is used to flatten a fair few logical tests in the framework, typically related to Objective-C interoperability.
    internal var nonEmpty: Self? {
        guard !self.isEmpty else { return nil }
        
        return self
    }
    
    internal func count(where predicate: (Element) -> Bool) -> Int {
        return self.reduce(into: 0, { total, element in
            if predicate(element) {
                total += 1
            }
        })
    }
}
