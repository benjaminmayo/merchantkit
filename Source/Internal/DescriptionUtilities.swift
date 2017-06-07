extension CustomStringConvertible {
    internal func defaultDescription(withProperties properties: (String, Any)...) -> String {
        let formattedProperties = properties.map { (arg) in
            
            let (name, value) = arg
            if name.isEmpty {
                return "\(value)"
            } else {
                return "\(name): \(value)"
            }
        }.joined(separator: ", ")
        
        let description = "[\(type(of: self)) \(formattedProperties)]"
        
        return description
    }
}
