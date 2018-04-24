extension CustomStringConvertible {
    internal func defaultDescription(typeName: String = "", withProperties properties: (String, Any)...) -> String {
        let formattedProperties = properties.map { property in
            let (name, value) = property
            
            if name.isEmpty {
                return "\(value)"
            } else {
                return "\(name): \(value)"
            }
        }.joined(separator: ", ")
        
        let typeName = typeName.isEmpty ? "\(type(of: self))" : typeName
        let description = "[\(typeName) \(formattedProperties)]"
        
        return description
    }
}
