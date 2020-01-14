//
//  DataTargetType.swift
//  Quicksilver
//
//  Created by Chun Ye on 2018/9/21.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import Foundation
import AFNetworkingPrivate

// MARK: - DataTargetType

public protocol DataTargetType: TargetType {
  /// The target's base `URL`.
  var baseURL: URL { get }
  
  /// The path to be appended to `baseURL` to form the full `URL`.
  var path: String { get }
  
  /// Provides stub data for use in testing. Default is nil.
  var sampleResponse: SampleResponseClosure? { get }
}

public extension DataTargetType {
  
  /// Default value is `.successCodes`.
  var validation: ValidationType {
    return .successCodes
  }
  
  var sampleResponse: SampleResponseClosure? {
    return nil
  }
  
  /// Default value is nil.
  var parameters: [String: Any]? {
    return nil
  }
  
  var headers: [String: String]? {
    return nil
  }
  
  var fullRequestURL: URL {
    
    // Ensure terminal slash for baseURL path, so that NSURL +URLWithString:relativeToURL: works as expected
    var finalBaseURL = baseURL
    if finalBaseURL.path.count > 0 && !finalBaseURL.absoluteString.hasSuffix("/") {
      finalBaseURL = finalBaseURL.appendingPathComponent("")
    }
    if let url = URL(string: path, relativeTo: finalBaseURL) {
      return url
    } else {
      fatalError("\(baseURL) relative \(path) failed, please double check.")
    }
  }
  
  var priority: Float {
    return 0.5
  }
  
  var timeoutInterval: TimeInterval? {
    return nil
  }
}

// MARK: - SampleResponse

/// Used for stubbing responses.
public enum SampleResponse {
  
  /// The network returned a response, including status code and data.
  case networkResponse(Int, Data)
  
  /// The network returned response which can be fully customized.
  case response(HTTPURLResponse, Data)
  
  /// The network failed to send the request, or failed to retrieve a response (eg a timeout).
  case networkError(NSError)
}

public typealias SampleResponseClosure = () -> SampleResponse
