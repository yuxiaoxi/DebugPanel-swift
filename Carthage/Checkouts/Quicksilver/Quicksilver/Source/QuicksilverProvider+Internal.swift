//
//  QuicksilverProvider+Internal.swift
//  Quicksilver
//
//  Created by Chun on 14/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation
import AFNetworkingPrivate

func safeAsync(queue: DispatchQueue?, closure: @escaping () -> Void) {
  switch queue {
  case .none:
    if Thread.isMainThread {
      closure()
    } else {
      DispatchQueue.main.async {
        closure()
      }
    }
  case .some(let runQueue):
    runQueue.async {
      closure()
    }
  }
}

extension QuicksilverProvider {
  
  func configSessionManager() {
    
    sessionManager.responseSerializer = responseSeiralizer
    
    // Security
    if let certificatesBundle = configuration.certificatesBundle, configuration.httpsCertificateLocalVerify {
      let certificateData = AFSecurityPolicy.certificates(in: certificatesBundle)
      sessionManager.securityPolicy = AFSecurityPolicy(pinningMode: .certificate, withPinnedCertificates: certificateData)
    }
    
    sessionManager.setSessionDidReceiveAuthenticationChallenge { [weak self] (_, challenge, credential) -> URLSession.AuthChallengeDisposition in
      if let strongSelf = self {
        var disposition = URLSession.AuthChallengeDisposition.performDefaultHandling
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
          if let serverTrust = challenge.protectionSpace.serverTrust {
            if strongSelf.sessionManager.securityPolicy.evaluateServerTrust(serverTrust, forDomain: challenge.protectionSpace.host) {
              disposition = URLSession.AuthChallengeDisposition.useCredential
              credential?.pointee = URLCredential(trust: serverTrust)
            } else if let domain = HTTPDNS.getOriginDomain(ipAddress: challenge.protectionSpace.host), strongSelf.sessionManager.securityPolicy.evaluateServerTrust(serverTrust, forDomain: domain) {
              disposition = URLSession.AuthChallengeDisposition.useCredential
              credential?.pointee = URLCredential(trust: serverTrust)
            } else {
              disposition = URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge
            }
          } else {
            disposition = URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge
          }
        }
        return disposition
      } else {
        return URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge
      }
    }
  }
  
  /// Creates a function which, when called, executes the appropriate stubbing behavior for the given parameters.
  /// Only support Data Target Type.
  func createStubFunction(_ token: TaskToken, forTarget target: TargetType, withCompletion completion: @escaping Completion, plugins: [PluginType], request: URLRequest) -> (() -> Void) {
    if let target = target as? DataTargetType {
      return {
        if token.isCancelled {
          self.cancelCompletion(completion, target: target)
          return
        }
        
        let validate = { (response: Response) -> Result<Response, QuicksilverError> in
          let validCodes = target.validation.statusCodes
          guard !validCodes.isEmpty else { return .success(response) }
          if validCodes.contains(response.statusCode) {
            return .success(response)
          } else {
            let statusError = QuicksilverError.statusCode(response)
            let error = QuicksilverError.underlying(statusError, response)
            return .failure(error)
          }
        }
        
        if let sampleResponseClosure = target.sampleResponse {
          switch sampleResponseClosure() {
          case .networkResponse(let statusCode, let data):
            let response = Response(statusCode: statusCode, data: data, request: request, response: nil)
            let result = validate(response)
            plugins.forEach { $0.didReceive(result, target: target) }
            completion(result)
          case .response(let customResponse, let data):
            let response = Response(statusCode: customResponse.statusCode, data: data, request: request, response: customResponse)
            let result = validate(response)
            plugins.forEach { $0.didReceive(result, target: target) }
            completion(result)
          case .networkError(let error):
            let error = QuicksilverError.underlying(error, nil)
            plugins.forEach { $0.didReceive(.failure(error), target: target) }
            completion(.failure(error))
          }
        } else {
          let error = QuicksilverError.underlying(NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil), nil)
          plugins.forEach { $0.didReceive(.failure(error), target: target) }
          completion(.failure(error))
        }
      }
    } else {
      fatalError("Stub function only support Data Target Type.")
    }
    
  }
  
  func requestNormal(_ target: TargetType, callbackQueue: DispatchQueue?, progress: ProgressBlock? = .none, completion: @escaping Completion) -> TaskToken {
    let pluginsWithCompletion: Completion = { result in
      let processedResult = self.plugins.reduce(result) { $1.process($0, target: target) }
      completion(processedResult)
    }
    let result: (URLRequest?, QuicksilverError?, String?) = getTargetRequest(target)
    if let request = result.0 {
      let preparedRequest = self.plugins.reduce(request) { $1.prepare($0, target: target) }
      return performRequest(target, request: preparedRequest, callbackQueue: callbackQueue, progress: progress, originHost: result.2, completion: pluginsWithCompletion)
    } else {
      let task = TaskToken.simpleTask()
      let finalError = result.1 ?? QuicksilverError.requestMapping(target)
      pluginsWithCompletion(.failure(finalError))
      task.cancel()
      return task
    }
  }
  
  func performRequest(_ target: TargetType, request: URLRequest, callbackQueue: DispatchQueue?, progress: ProgressBlock?, originHost: String?, completion: @escaping Completion) -> TaskToken {
    if let target = target as? DataTargetType {
      if case .never = configuration.stub {
        return sendRequest(target, request: request, callbackQueue: callbackQueue, progress: nil, originHost: originHost, completion: completion)
      } else if target.sampleResponse == nil {
        return sendRequest(target, request: request, callbackQueue: callbackQueue, progress: nil, originHost: originHost, completion: completion)
      } else {
        return performStubRequest(target, callbackQueue: callbackQueue, completion: completion, stubBehavior: configuration.stub)
      }
    } else if let target = target as? DownloadTargetType {
      return sendRequest(target, request: request, callbackQueue: callbackQueue, progress: progress, originHost: originHost, completion: completion)
    } else if let target = target as? UploadTargetType {
      return sendRequest(target, request: request, callbackQueue: callbackQueue, progress: progress, originHost: originHost, completion: completion)
    } else {
      fatalError("\(target) not support")
    }
  }
  
  func performStubRequest(_ target: DataTargetType, callbackQueue: DispatchQueue?, completion: @escaping Completion, stubBehavior: StubBehavior) -> TaskToken {
    let callbackQueue = callbackQueue ?? self.callbackQueue
    let stubTask = TaskToken.stubTask()
    let requestResult = getTargetRequest(target)
    if let request = requestResult.0 {
      plugins.forEach { $0.willSend(request, target: target) }
      let stub: () -> Void = createStubFunction(stubTask, forTarget: target, withCompletion: completion, plugins: plugins, request: request)
      switch stubBehavior {
      case .immediate:
        safeAsync(queue: callbackQueue) {
          stubTask.finished()
          stub()
        }
      case .delayed(let delay):
        let killTimeOffset = Int64(CDouble(delay) * CDouble(NSEC_PER_SEC))
        let killTime = DispatchTime.now() + Double(killTimeOffset) / Double(NSEC_PER_SEC)
        (callbackQueue ?? DispatchQueue.main).asyncAfter(deadline: killTime) {
          stubTask.finished()
          stub()
        }
      case .never:
        fatalError("Method called to stub request when stubbing is disabled.")
      }
    } else {
      safeAsync(queue: callbackQueue) {
        stubTask.finished()
        completion(Result<Response, QuicksilverError>.failure(QuicksilverError.requestMapping(target)))
      }
    }
    return stubTask
  }
  
  func cancelCompletion(_ completion: Completion, target: TargetType) {
    let error = QuicksilverError.underlying(NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil), nil)
    plugins.forEach { $0.didReceive(.failure(error), target: target) }
    completion(.failure(error))
  }
  
  func getTargetRequest(_ target: TargetType) -> (URLRequest?, QuicksilverError?, String?) {
    
    func request(_ finalURL: URL, originHost: String? = nil, dnsResult: HTTPDNSResult? = nil) -> (URLRequest?, QuicksilverError?, String?) {
      let fullUrlString = finalURL.absoluteString
      var serializationError: NSError?
      var mergedParams: [String: Any] = target.parameters ?? [:]
      plugins.forEach { plugin in
        if let extraParameters = plugin.extraParameters {
          extraParameters.forEach { (key, value) in
            mergedParams[key] = value
          }
        }
      }
      var request: NSMutableURLRequest
      if let target = target as? UploadTargetType, case .multipartForm(let constructingBody) = target.uploadType {
        request = requestSerializer.multipartFormRequest(withMethod: target.method.rawValue, urlString: fullUrlString, parameters: mergedParams, constructingBodyWith: { (data) in
          let updateData = MultipartformData(data: data)
          constructingBody(updateData)
        }, error: &serializationError)
      } else {
        request = requestSerializer.request(withMethod: target.method.rawValue, urlString: fullUrlString, parameters: mergedParams, error: &serializationError)
      }
      
      if let timeout = target.timeoutInterval {
        request.timeoutInterval = timeout
      }
      
      if let error = serializationError {
        return (nil, QuicksilverError.underlying(error, nil), nil)
      } else {
        if let headers = target.headers {
          headers.forEach { (key, value) in
            request.setValue(value, forHTTPHeaderField: key)
          }
        }
        if let originHost = originHost {
          request.setValue(originHost, forHTTPHeaderField: "Host")
        }
        if let originHost = originHost, let dnsResult = dnsResult, dnsResult.fromCached {
          return (request as URLRequest, nil, originHost)
        } else {
          return (request as URLRequest, nil, nil)
        }
      }
    }
    
    let url = target.fullRequestURL
    if let host = url.host, checkShouldUseHTTPDNS(target: target) {
      if let result = HTTPDNS.query(host), let range = url.absoluteString.range(of: host) {
        let ip = result.ipAddress
        let newURLString = url.absoluteString.replacingCharacters(in: range, with: ip)
        if let newURL = URL(string: newURLString) {
          return request(newURL, originHost: host, dnsResult: result)
        } else {
          return request(url)
        }
      } else {
        return request(url)
      }
    } else {
      return request(url)
    }
    
  }
  
  private func checkShouldUseHTTPDNS(target: TargetType) -> Bool {
    if let target = target as? DataTargetType {
      let useHTTPDNS: Bool
      switch configuration.stub {
      case .delayed, .immediate:
        if target.sampleResponse != nil {
          useHTTPDNS = false
        } else {
          useHTTPDNS = configuration.useHTTPDNS
        }
      case .never:
        useHTTPDNS = configuration.useHTTPDNS
      }
      return useHTTPDNS
    } else if let target = target as? DownloadTargetType {
      if let scheme = target.resource.url.scheme, scheme != "https" {
        return configuration.useHTTPDNS
      } else {
        return false
      }
    } else {
      return configuration.useHTTPDNS
    }
  }
  
}
