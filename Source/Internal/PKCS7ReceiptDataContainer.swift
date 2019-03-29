import Foundation

internal final class PKCS7ReceiptDataContainer {
    private let parser: ASN1.Parser
    
    private var isStartingContentDataSection: Bool = false
    private var extractedContent: Data?
    
    init(receiptData: Data) {
        self.parser = ASN1.Parser(data: receiptData)
        self.parser.delegate = self
    }
    
    func content() throws -> Data {
        defer {
            self.reset()
        }
        
        do {
            try self.parser.parse()
        } catch ASN1.Parser.Error.aborted {
            
        }
        
        guard let data = self.extractedContent else {
            throw Error.malformedContainer
        }
        
        return data
    }
    
    enum Error : Swift.Error {
        case malformedContainer
    }
}

extension PKCS7ReceiptDataContainer {
    private func reset() {
        self.extractedContent = nil
        self.isStartingContentDataSection = false
    }
}

extension PKCS7ReceiptDataContainer : ASN1ParserDelegate {
    func asn1Parser(_ parser: ASN1.Parser, didParse token: ASN1.Parser.Token) {
        switch token {
            case .value(.objectIdentifier(let objectIdentifier)):
                if objectIdentifier.stringValue == PKCS7ObjectIdentifiers.data {
                    self.isStartingContentDataSection = true
                }
            case .value(.data(let data)) where self.isStartingContentDataSection:
                self.extractedContent = data
                parser.abortParsing()
            default:
                break
        }
    }
}

private enum PKCS7ObjectIdentifiers {
    static let data = "1.2.840.113549.1.7.1"
    static let signedData = "1.2.840.113549.1.7.2"
    static let envelopedData = "1.2.840.113549.1.7.3"
    static let signedAndEnvelopedData = "1.2.840.113549.1.7.4"
    static let digestedData = "1.2.840.113549.1.7.5"
    static let encryptedData = "1.2.840.113549.1.7.6"
}
