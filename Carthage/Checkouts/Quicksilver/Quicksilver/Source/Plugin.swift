//
//  Plugin.swift
//  Quicksilver
//
//  Created by Chun on 14/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation

/// A Quicksilver Plugin receives callbacks to perform side effects wherever a request is sent or received.
///
/// for example, a plugin may be used to
///     - log network requests
///     - hide and show a network activity indicator
///     - inject additional information into a request
public protocol PluginType {
  
  /// etra parameters, will merge to any TargetType parameters
  var extraParameters: [String: Any]? { get }
  
  /// Called to modify a request before sending.
  func prepare(_ request: URLRequest, target: TargetType) -> URLRequest
  
  /// Called immediately before a request is sent over the network (or stubbed).
  func willSend(_ request: URLRequest, target: TargetType)
  
  /// Called after a response has been received, but before the QuicksilverProvider has invoked its completion handler.
  func didReceive(_ result: Result<Response, QuicksilverError>, target: TargetType)
  
  /// Called to modify a result before completion.
  func process(_ result: Result<Response, QuicksilverError>, target: TargetType) -> Result<Response, QuicksilverError>
}

public extension PluginType {
  var extraParameters: [String: Any]? { return nil }
  func prepare(_ request: URLRequest, target: TargetType) -> URLRequest { return request }
  func willSend(_ request: URLRequest, target: TargetType) { }
  func didReceive(_ result: Result<Response, QuicksilverError>, target: TargetType) { }
  func process(_ result: Result<Response, QuicksilverError>, target: TargetType) -> Result<Response, QuicksilverError> { return result }
}
