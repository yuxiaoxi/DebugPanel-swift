//
//  QuicksilverProvider.swift
//  Quicksilver
//
//  Created by Chun on 13/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation
import AFNetworkingPrivate

/// Closure to be executed when a request has completed.
public typealias Completion = (_ result: Result<Response, QuicksilverError>) -> Void

public typealias ProgressBlock = (Progress) -> Void

/// QuicksilverProvider supports Data request, like REST API.
open class QuicksilverProvider {
  
  /// A list of plugins.
  /// e.g. for logging, network activity indicator or credentials.
  public let plugins: [PluginType]
  
  /// session Manager session configuration, includes https local verify and httpdns config
  public let configuration: QuicksilverURLSessionConfiguration

  deinit {
    sessionManager.invalidateSessionCancelingTasks(true)
  }
  
  /// Initializes a provider for data request.
  public init(configuration: QuicksilverURLSessionConfiguration = QuicksilverURLSessionConfiguration(),
              plugins: [PluginType] = [],
              callbackQueue: DispatchQueue? = nil) {
    self.callbackQueue = callbackQueue
    self.plugins = plugins
    self.configuration = configuration
    
    self.requestSerializer = configuration.requestParamaterEncodeType.requestSerialization
    self.responseSeiralizer = QuicksilverHTTPResponseSerialization()
    
    self.sessionManager = AFURLSessionManager(sessionConfiguration: configuration.urlSessionConfiguration)
    
    configSessionManager()
  }
  
  @discardableResult public func request(_ dataTarget: DataTargetType,
                                         callbackQueue: DispatchQueue? = .none,
                                         progress: ProgressBlock? = .none,
                                         completion: @escaping Completion) -> QuicksilverDataTask {
    let callbackQueue = callbackQueue ?? self.callbackQueue
    return requestNormal(dataTarget, callbackQueue: callbackQueue, progress: progress, completion: completion)
  }
  
  @discardableResult public func download(_ downloadTarget: DownloadTargetType,
                                          callbackQueue: DispatchQueue? = .none,
                                          progress: ProgressBlock? = .none,
                                          completion: @escaping Completion) -> QuicksilverDownloadTask {
    let callbackQueue = callbackQueue ?? self.callbackQueue
    return requestNormal(downloadTarget, callbackQueue: callbackQueue, progress: progress, completion: completion)
  }
  
  @discardableResult public func upload(_ uploadTarget: UploadTargetType,
                                        callbackQueue: DispatchQueue? = .none,
                                        progress: ProgressBlock? = .none,
                                        completion: @escaping Completion) -> QuicksilverUploadTask {
    let callbackQueue = callbackQueue ?? self.callbackQueue
    return requestNormal(uploadTarget, callbackQueue: callbackQueue, progress: progress, completion: completion)
  }
  
  /// Only support Data Target Type.
  /// StubRequest Task only supports `cancel`, resume and suspend is not working.
  @discardableResult
  public func stubRequest(_ target: DataTargetType, callbackQueue: DispatchQueue?, completion: @escaping Completion, stubBehavior: StubBehavior) -> QuicksilverDataTask {
    return performStubRequest(target, callbackQueue: callbackQueue, completion: completion, stubBehavior: stubBehavior)
  }
  
  // MARK: - Internal
  
  /// Propagated as callback queue. If nil - the main queue will be used.
  let callbackQueue: DispatchQueue?
  
  /// SessionManager for Rest API request
  let sessionManager: AFURLSessionManager
  
  let requestSerializer: AFHTTPRequestSerializer
  let responseSeiralizer: QuicksilverHTTPResponseSerialization
}
