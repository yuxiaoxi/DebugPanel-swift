//
//  SingleRequestWorker.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/1/2.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

final class SingleRequestWorker {
  
  private let extraErrorMappings: [RussellError.ErrorMapping]
  init(extraErrorMappings: [RussellError.ErrorMapping]) {
    self.extraErrorMappings = extraErrorMappings
  }
  
  private var sessionTask: Cancellable?
  private var requestID: UUID?
  
  private let stateLock = DispatchSemaphore(value: 1)
  private var isInvalid = false
  
  func invalidate() {
    
    defer { stateLock.signal() }
    stateLock.wait()
    
    requestID = nil
    cancelCurrentSessionTaskIfNeeded()
    sessionTask = nil
    isInvalid = true
  }
  
  func sendRequest(api: API<Void>, service: NetworkService, completion: @escaping (RussellResult<Void>) -> Void) {
    sendRequest(api: api,
                decoder: { _ in },
                service: service,
                completion: completion)
  }
  
  func sendRequest<Value: Decodable>(api: API<Value>, service: NetworkService, completion: @escaping (RussellResult<Value>) -> Void) {
    sendRequest(api: api,
                decoder: { try JSONDecoder().decode(Value.self, from: $0) },
                service: service,
                completion: completion)
  }
  
  private func cancelCurrentSessionTaskIfNeeded() {
    guard let sessionTask = sessionTask else { return }
    
    Logger.info("Session task will be canceled due to external operation: \(sessionTask)")
    sessionTask.cancel()
  }
  
  private func sendRequest<Value>(api: API<Value>, decoder: @escaping (Data) throws -> Value, service: NetworkService, completion: @escaping (RussellResult<Value>) -> Void) {
    defer { stateLock.signal() }
    stateLock.wait()
    
    guard !isInvalid else {
      return DispatchQueue.global().async {
        completion(.failure(RussellError.Common.sessionInvalidated))
      }
    }
    
    let requestID = UUID()
    self.requestID = requestID
    cancelCurrentSessionTaskIfNeeded()
    sessionTask = service.request(api: api, extraErrorMapping: extraErrorMappings, decoder: decoder) { result in
      defer { self.stateLock.signal() }
      self.stateLock.wait()
      
      guard
        !self.isInvalid,
        self.requestID == requestID
        else { return }
      
      self.sessionTask = nil
      // use global queue to avoid deadlock (calling sendRequest in completion will cause deadlock)
      DispatchQueue.global().async {
        completion(result)
      }
    }
  }
}
