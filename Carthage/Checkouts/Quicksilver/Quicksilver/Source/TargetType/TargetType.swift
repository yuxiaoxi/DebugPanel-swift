//
//  TargetType.swift
//  Quicksilver
//
//  Created by Chun Ye on 2018/9/21.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation
import AFNetworkingPrivate

// MARK: - TaskType

public protocol TargetType {
  /// The type of validation to perform on the request.
  var validation: ValidationType { get }
  
  /// The HTTP method used in the request.
  var method: HTTPMethod { get }
  
  /// A request body set with encoded parameters.
  var parameters: [String: Any]? { get }
  
  /// The headers to be used in the request. Default is nil.
  var headers: [String: String]? { get }
  
  /// request final url
  var fullRequestURL: URL { get }
  
  /// The relative priority at which you’d like a host to handle the task, specified as a floating point value between 0.0 (lowest priority) and 1.0 (highest priority).
  /// To provide hints to a host on how to prioritize URL session tasks from your app, specify a priority for each task. Specifying a priority provides only a hint and does not guarantee performance. If you don’t specify a priority, a URL session task has a priority of NSURLSessionTaskPriorityDefault, with a value of 0.5.
  var priority: Float { get }
  
  /// Returns the timeout interval of the receiver.
  /// - discussion: The timeout interval specifies the limit on the idle
  /// interval allotted to a request in the process of loading. The "idle
  /// interval" is defined as the period of time that has passed since the
  /// last instance of load activity occurred for a request that is in the
  /// process of loading. Hence, when an instance of load activity occurs
  /// (e.g. bytes are received from the network for a request), the idle
  /// interval for a request is reset to 0. If the idle interval ever
  /// becomes greater than or equal to the timeout interval, the request
  /// is considered to have timed out. This timeout interval is measured
  /// in seconds.
  var timeoutInterval: TimeInterval? { get }
}

public extension TargetType {
  
  var timeoutInterval: TimeInterval? {
    return nil
  }

}
