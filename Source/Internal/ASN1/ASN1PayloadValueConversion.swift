import Foundation

extension ASN1 {
    enum PayloadValueConversionError : Swift.Error {
        case invalidBufferSize(foundByteCount: Int, payloadType: BufferType)
        case unsupportedEncoding(payloadType: BufferType)
        case invalidDateFormat(String)
        case unsupportedBuffer(payloadType: BufferType)
        case invalidLength
    }
    
    static func integer(from buffer: Data) -> Int {
        return buffer.reduce(0, { result, byte in
            (result << 8) | Int(byte)
        })
    }
    
    typealias ConsumingConversionResult<T> = (value: T, remainingData: Data)
    
    static func consumeLength(from data: Data) throws -> ConsumingConversionResult<Int> {
        guard let byte = data.first else { throw PayloadValueConversionError.invalidLength }
        
        let next = data.index(after: data.startIndex)
        
        if ((byte & 0x80) == 0x00) {
            return (Int(byte), data[next...])
        }
        
        let byteCount = Int(byte & 0x7f)
        
        guard byteCount > 0 else {
            throw PayloadValueConversionError.invalidLength // infinite length not supported
        }
        
        if next.advanced(by: byteCount) >= data.endIndex {
            throw PayloadValueConversionError.invalidLength
        }
        
        let endIndex = data.index(next, offsetBy: byteCount)
        let buffer = data[next..<endIndex]
        
        let integer = ASN1.integer(from: buffer)
        
        guard integer > 0 else {
            throw PayloadValueConversionError.invalidLength
        }
        
        return (integer, data[endIndex...])
    }
    
    static func value(convertedFrom buffer: Data, as bufferType: BufferType) throws -> ASN1.BufferValue {
        if buffer.isEmpty {
            let allowedZeroLengthTypes: Set<BufferType> = [.null, .teletexString, .graphicString, .printableString, .utf8String, .ia5String]
            
            if !allowedZeroLengthTypes.contains(bufferType) {
                throw PayloadValueConversionError.invalidBufferSize(foundByteCount: 0, payloadType: bufferType)
            }
        }
        
        switch bufferType {
            case .boolean:
                guard buffer.count == 1 else { throw PayloadValueConversionError.invalidBufferSize(foundByteCount: buffer.count, payloadType: bufferType) }
                
                let byte = buffer.first!
                
                let value = byte != 0
                return .boolean(value)
            case .integer:
                let value = ASN1.integer(from: buffer)
                
                return .integer(value)
            case .bitString:
                return .data(buffer)
            case .octetString:
                return .data(buffer)
            case .null:
                return .null
            case .objectIdentifier, .relativeObjectIdentifier:
                let objectIdentifier = ASN1.ObjectIdentifier(bytes: buffer)
                return .objectIdentifier(objectIdentifier)
            case .teletexString, .graphicString, .printableString, .utf8String, .ia5String:
                guard let string = String(data: buffer, encoding: .utf8) else { throw PayloadValueConversionError.unsupportedBuffer(payloadType: bufferType) }
                
                return .string(string)
            case .utcTime, .generalizedTime:
                let string = String(data: buffer, encoding: .ascii)!
                
                return .date(string)
            default:
                throw PayloadValueConversionError.unsupportedBuffer(payloadType: bufferType)
        }
    }
}
