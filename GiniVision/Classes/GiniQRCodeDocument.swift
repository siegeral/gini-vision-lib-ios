//
//  GiniQRCodeDocument.swift
//  Bolts
//
//  Created by Enrique del Pozo Gómez on 12/5/17.
//

import Foundation

@objc final public class GiniQRCodeDocument: NSObject, GiniVisionDocument {
    public var type: GiniVisionDocumentType = .qrcode
    public var data: Data
    public lazy var previewImage: UIImage? = {
       return self.generateQRCodeImage(from: self.data)
    }()
    public var isReviewable: Bool = false
    public var isImported: Bool = false
    public lazy var extractedParameters: [String: String] = self.extractParameters(from: self.scannedString)
    
    fileprivate let scannedString: String
    fileprivate let epc06912LinesCount = 12
    fileprivate lazy var qrCodeFormat: QRCodesFormat? = {
        if self.scannedString.starts(with: "bank://") {
            return .bezahlcode
        } else {
            return self.scannedString.splitlines.count == self.epc06912LinesCount ? .epc06912 : nil
        }
    }()
    
    fileprivate enum QRCodesFormat {
        case epc06912
        case bezahlcode
    }
    
    public init(scannedString: String) {
        self.data = scannedString.data(using: String.Encoding.isoLatin1) ?? Data(count: 0)
        self.scannedString = scannedString
        super.init()
    }
    
    public func checkType() throws {
        if self.qrCodeFormat == nil {
            throw DocumentValidationError.qrCodeFormatNotValid
        }
    }
    
    fileprivate func generateQRCodeImage(from data: Data) -> UIImage? {
        let filter = CIFilter(name: "CIQRCodeGenerator")
        
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("Q", forKey: "inputCorrectionLevel")
        
        if let outputImage = filter?.outputImage {
            return UIImage(ciImage: outputImage.applying(CGAffineTransform(scaleX: 2, y: 2)))
        }
        
        return nil
    }
}

extension GiniQRCodeDocument {
    public override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? GiniQRCodeDocument {
            return self.scannedString == object.scannedString
        }
        return false
    }
}

// MARK: Extractions

extension GiniQRCodeDocument {
    fileprivate func extractParameters(from string: String) -> [String: String] {
        switch qrCodeFormat {
        case .some(.bezahlcode):
            return extractParameters(fromBezhalCodeString: string)
        case .some(.epc06912):
            return extractParameters(fromEPC06912CodeString: string)
        case .none:
            return [:]
        }
    }
    
    fileprivate func extractParameters(fromBezhalCodeString string: String) -> [String: String] {
        var parameters: [String: String] = [:]
        
        if let queryParameters = URL(string: string)?.queryParameters {
            
            if let bic = queryParameters["bic"] as? String {
                parameters["bic"] = bic
            }
            if let paymentRecipient = queryParameters["name"] as? String {
                parameters["paymentRecipient"] = paymentRecipient
            }
            if let iban = queryParameters["iban"] as? String,
                IBANValidator().isValid(iban: iban) {
                parameters["iban"] = iban
            }
            if let paymentReference = queryParameters["reason"] as? String {
                parameters["paymentReference"] = paymentReference
            }
            if let amount = queryParameters["amount"] as? String,
                let currency = queryParameters["currency"] as? String,
                let amountNormalized = normalize(amount: amount, currency: currency) {
                parameters["amountToPay"] = amountNormalized
            }
        }
        
        return parameters
    }
    
    fileprivate func extractParameters(fromEPC06912CodeString string: String) -> [String: String] {
        let lines = string.splitlines
        var parameters: [String: String] = [
            "bic": lines[4],
            "paymentRecipient": lines[5],
            "paymentReference": lines[9]
        ]
        
        if IBANValidator().isValid(iban: lines[6]) {
            parameters["iban"] = lines[6]
        }
        
        if let amountToPay = normalize(amount: lines[7], currency: nil) {
            parameters["amountToPay"] = amountToPay
        }
        
        return parameters
    }
    
    fileprivate func normalize(amount: String, currency: String?) -> String? {
        let regexCurrency = try? NSRegularExpression(pattern: "[aA-zZ]", options: [])
        
        if let matches = regexCurrency?.matches(in: amount, options: [], range: NSRange(location: 0, length: 3)),
            matches.count == 3 {
            let currency = amount.substring(to: String.Index(encodedOffset: 3))
            let quantity = amount.substring(from: String.Index(encodedOffset: 3))
            return quantity + ":" + currency
        } else if let currency = currency {
            return amount + ":" + currency
        }
        
        return nil
    }
}