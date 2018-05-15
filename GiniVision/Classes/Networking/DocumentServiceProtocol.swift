//
//  DocumentServiceProtocol.swift
//  GiniVision
//
//  Created by Enrique del Pozo Gómez on 3/29/18.
//

import Foundation
import Gini_iOS_SDK

public typealias Extraction = GINIExtraction

enum AnalysisError: Error {
    case cancelled
    case documentCreation
    case unknown
}

typealias UploadDocumentCompletion = (Result<GINIDocument>) -> Void
typealias AnalysisCompletion = (Result<[String: Extraction]>) -> Void

protocol DocumentServiceProtocol: class {
    
    var giniSDK: GiniSDK { get }
    var compositeDocument: GINIDocument? { get set }
    var analysisCancellationToken: BFCancellationTokenSource? { get set }

    init(sdk: GiniSDK)
    func startAnalysis(completion: @escaping AnalysisCompletion)
    func cancelAnalysis()
    func remove(document: GiniVisionDocument)
    func upload(document: GiniVisionDocument,
                completion: UploadDocumentCompletion?)
    func update(imageDocument: GiniImageDocument)
}

extension DocumentServiceProtocol {
    
    var rotationDeltaKey: String { return "rotationDelta" }
    
    func upload(document: GiniVisionDocument) {
        self.upload(document: document,
                    completion: nil)
    }
    
    func createDocument(from document: GiniVisionDocument,
                        fileName: String,
                        docType: String = "",
                        cancellationToken: BFCancellationToken? = nil,
                        completion: @escaping UploadDocumentCompletion) {
        giniSDK.sessionManager
            .getSession()
            .continueWith(block: sessionBlock(cancellationToken: cancellationToken))
            .continueOnSuccessWith(block: { [weak self] _ in
                return self?.giniSDK.documentTaskManager.createPartialDocument(withFilename: fileName,
                                                                               from: document.data,
                                                                               docType: docType,
                                                                               cancellationToken: cancellationToken)
            }).continueWith(block: { task in
                if let createdDocument = task.result as? GINIDocument {
                    Logger.debug(message: "Created document with id: \(createdDocument.documentId ?? "") " +
                        "for vision document \(document.id)", event: .custom(emoji:"📄"))
                    completion(.success(createdDocument))
                } else if task.isCancelled {
                    completion(.failure(AnalysisError.cancelled))
                } else {
                    completion(.failure(AnalysisError.documentCreation))
                }
                
                return nil
            })
    }
    
    func deleteCompositeDocument(withId id: String) {
        giniSDK.sessionManager
            .getSession()
            .continueWith(block: sessionBlock(cancellationToken: nil))
            .continueOnSuccessWith(block: { [weak self] _ in
                    self?.giniSDK.documentTaskManager.deleteCompositeDocument(withId: id,
                                                                              cancellationToken: nil)
            })
            .continueWith(block: { task in
                if task.isCancelled || task.error != nil {
                    Logger.debug(message: "Error deleting composite document with id: \(id)", event: .error)
                } else {
                    Logger.debug(message: "Deleted composite document with id: \(id)", event: .custom(emoji:"🗑"))
                }
                
                return nil
            })

    }
    
    func deletePartialDocument(withId id: String) {
        giniSDK.sessionManager
            .getSession()
            .continueWith(block: sessionBlock(cancellationToken: nil))
            .continueOnSuccessWith(block: { [weak self] _ in
                self?.giniSDK.documentTaskManager.deletePartialDocument(withId: id,
                                                                        cancellationToken: nil)
            })
            .continueWith(block: { task in
                if task.isCancelled || task.error != nil {
                    Logger.debug(message: "Error deleting partial document with id: \(id)", event: .error)
                } else {
                    Logger.debug(message: "Deleted partial document with id: \(id)", event: .custom(emoji:"🗑"))
                }
                
                return nil
            })

    }
    
    func fetchExtractions(for documents: [GINIPartialDocumentInfo],
                          completion: @escaping AnalysisCompletion) {
        analysisCancellationToken = BFCancellationTokenSource()
        let fileName = "Composite-\(NSDate().timeIntervalSince1970)"
        
        giniSDK
            .documentTaskManager
            .createCompositeDocument(withPartialDocumentsInfo: documents,
                                     fileName: fileName,
                                     docType: "",
                                     cancellationToken: analysisCancellationToken?.token)
            .continueOnSuccessWith { task in
                if let document = task.result as? GINIDocument {
                    self.compositeDocument = document
                    return self.giniSDK.documentTaskManager.getExtractionsFor(document)
                }
                return BFTask<AnyObject>(error: AnalysisError.documentCreation)
            }
            .continueWith(block: handleAnalysisResults(completion: completion))
        
    }
    
    func handleAnalysisResults(completion: @escaping AnalysisCompletion)
        -> ((BFTask<AnyObject>) -> Any?) {
            return { task in
                if task.isCancelled {
                    Logger.debug(message: "Cancelled analysis process", event: .error)
                    completion(.failure(AnalysisError.documentCreation))
                    
                    return BFTask<AnyObject>.cancelled()
                }
                
                let finishedString = "Finished analysis process with"
                
                if let error = task.error {
                    Logger.debug(message: "\(finishedString) this error: \(error)", event: .error)
                    
                    completion(.failure(error))
                } else if let result = task.result as? [String: Extraction] {
                    Logger.debug(message: "\(finishedString) no errors", event: .success)
                    
                    completion(.success(result))
                } else {
                    let error = NSError(domain: "net.gini.error.", code: AnalysisError.unknown._code, userInfo: nil)
                    Logger.debug(message: "\(finishedString) this error: \(error)", event: .error)

                    completion(.failure(AnalysisError.unknown))
                }
                
                return nil
            }
    }
    
    func sendFeedback(with updatedExtractions: [String: Extraction]) {
        giniSDK.sessionManager
            .getSession()
            .continueWith(block: sessionBlock())
            .continueOnSuccessWith(block: { _ in
                return self.giniSDK
                .documentTaskManager?
                    .update(self.compositeDocument,
                            updatedExtractions: updatedExtractions,
                            cancellationToken: nil)
            })
            .continueWith(block: { (task: BFTask?) in
                if let error = task?.error {
                    let id = self.compositeDocument?.documentId ?? ""
                    let message = "Error sending feedback for document with id: \(id) error: \(error)"
                    Logger.debug(message: message, event: .error)
                    
                    return nil
                }
                
                Logger.debug(message: "Feedback sent with \(updatedExtractions.count) extractions",
                    event: .custom(emoji:"🚀"))

                return nil
            })
    }
    
    func sessionBlock(cancellationToken token: BFCancellationToken? = nil)
        -> ((BFTask<AnyObject>) -> Any?) {
            return {
                [weak self] task in
                guard let `self` = self else { return nil }
                
                if task.error != nil {
                    return self.giniSDK.sessionManager.logIn()
                }
                return task.result
            }
    }
    
}
