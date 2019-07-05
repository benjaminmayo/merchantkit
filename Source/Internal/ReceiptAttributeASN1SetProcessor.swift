import Foundation

internal protocol ReceiptAttributeASN1SetProcessorDelegate : AnyObject {
    func receiptAttributeASN1SetProcessor(_ processor: ReceiptAttributeASN1SetProcessor, didFind attribute: ReceiptAttributeASN1SetProcessor.ReceiptAttribute)
}

/// This class processes an ASN1 set of sequences as defined by the Apple In-App Purchase receipt specification. `data` should start at the first byte of the set, including the payload descriptor.
internal class ReceiptAttributeASN1SetProcessor : Equatable {
    // Long term, would consider refactoring into a `Sequence` of `Token`s. This would likely require re-engineering the underlying event parser.
    
    weak var delegate: ReceiptAttributeASN1SetProcessorDelegate?
    
    private let parser: ASN1.Parser
    private var parsingState = ParsingState()
    
    init(data: Data) {
        self.parser = ASN1.Parser(data: data)
        self.parser.delegate = self
    }
    
    func start() throws {
        try self.parser.parse()
    }
    
    struct ReceiptAttribute {
        let type: Int
        let version: Int
        
        private let data: Data
        
        fileprivate init?(from possibleAttributeData: PossibleReceiptAttributeData) {
            guard let type = possibleAttributeData.type, let version = possibleAttributeData.version, let data = possibleAttributeData.data else {
                return nil
            }
            
            self.type = type
            self.version = version
            self.data = data
        }
        
        internal init(type: Int, version: Int, data: Data) {
            self.type = type
            self.version = version
            self.data = data
        }
        
        var rawBuffer: Data {
            return self.data
        }
        
        private var bufferWithType: (ASN1.BufferType, buffer: Data)? {
            guard let firstByte = self.data.first, let bufferType = ASN1.BufferType(rawValue: firstByte) else {
                return nil
            }
            
            guard let (length, remaining) = try? ASN1.consumeLength(from: self.data[self.data.index(after: self.data.startIndex)...]) else { return nil }
            
            guard length <= remaining.count else { return nil }
            
            return (bufferType, remaining)
        }
        
        var stringValue: String? {
            guard let (type, buffer) = self.bufferWithType else { return nil }
            
            let value = try? ASN1.value(convertedFrom: buffer, as: type)
            
            switch value {
                case .string(let string)?:
                    return string
                default:
                    return nil
            }
        }
        
        var integerValue: Int? {
            guard let (type, buffer) = self.bufferWithType else { return nil }
            
            let value = try? ASN1.value(convertedFrom: buffer, as: type)
            
            switch value {
                case .integer(let integer)?:
                    return integer
                default:
                    return nil
            }
        }

        var iso8601DateValue: Date? {
            return self.stringValue.flatMap { Date(fromISO8601: $0) }
        }
    }
    
    static func == (lhs: ReceiptAttributeASN1SetProcessor, rhs: ReceiptAttributeASN1SetProcessor) -> Bool {
        return lhs === rhs
    }
    
    private struct ParsingState {
        var hasStartedSet: Bool = false
        var currentAttributeData: PossibleReceiptAttributeData?
        var nextExpectedValue: ExpectedValue?
        
        enum ExpectedValue {
            case type
            case version
            case data
        }
    }
    
    fileprivate struct PossibleReceiptAttributeData {
        var type: Int!
        var version: Int!
        var data: Data!
        
        init() {
            self.type = nil
            self.version = nil
            self.data = nil
        }
    }
    
    private func process(_ receiptAttribute: ReceiptAttribute) {
        self.delegate?.receiptAttributeASN1SetProcessor(self, didFind: receiptAttribute)
    }
}

extension ReceiptAttributeASN1SetProcessor : ASN1ParserDelegate {
    func asn1Parser(_ parser: ASN1.Parser, didParse token: ASN1.Parser.Token) {
        switch token {
            case .containerStart(type: .set):
                self.parsingState.hasStartedSet = true
            case .containerEnd(type: .set) where self.parsingState.hasStartedSet:
                parser.abortParsing()
            case .containerStart(type: .sequence) where self.parsingState.hasStartedSet:
                self.parsingState.currentAttributeData = PossibleReceiptAttributeData()
                self.parsingState.nextExpectedValue = .type
            case .containerEnd(type: .sequence) where self.parsingState.hasStartedSet:
                if let parsedAttributeData = self.parsingState.currentAttributeData {
                    if let attribute = ReceiptAttribute(from: parsedAttributeData) {
                        self.process(attribute)
                    }
                }
                
                self.parsingState.currentAttributeData = nil
                self.parsingState.nextExpectedValue = nil
            case .value(.integer(let integer)) where self.parsingState.nextExpectedValue == .type:
                self.parsingState.currentAttributeData?.type = integer
                self.parsingState.nextExpectedValue = .version
            case .value(.integer(let integer)) where self.parsingState.nextExpectedValue == .version:
                self.parsingState.currentAttributeData?.version = integer
                self.parsingState.nextExpectedValue = .data
            case .value(.data(let data)) where self.parsingState.nextExpectedValue == .data:
                self.parsingState.currentAttributeData?.data = data
            default:
                break
        }
    }
}
