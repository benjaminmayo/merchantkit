import Foundation

internal struct LocalReceiptDataDecoder {
    init() {
        
    }
    
    func decode(_ receiptData: Data) throws -> Receipt {
        let container = PKCS7ReceiptDataContainer(receiptData: receiptData)
        let content = try container.content()
    
        let parser = LocalReceiptPayloadParser()
    
        return try parser.receipt(from: content)
    }
}
