//
//  QuicksilverPlugin.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/3/20.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

public typealias RefreshTokenOperation = (_ completion: @escaping (Error?) -> Void) -> Void

/// Quicksilver Plugin For 401 / 403 status code handling.
///
/// on 401，it will try to refresh token, and call `refreshTokenFailedAfter401Callback` if refresh token fails with reason "notLoggedIn" or "invalidToken".
/// on 403, it will just try to trigger refresh token operation without caring the result.
public final class RefreshTokenOn401Or403Plugin: PluginType {
  
  private let refreshTokenFailedAfter401Or403Callback: (() -> Void)
  private let refreshOn401Or403Lock = NSLock()
  
  /// How to refresh token. Default is using Russell.shared and complete with error if Russell is not set up.
  public var refreshTokenOperation: RefreshTokenOperation = { completion in
    guard let russell = Russell.shared else {
      return completion(NSError(domain: "Russell", code: -1, userInfo: [NSLocalizedDescriptionKey: "Russell service not ready"]))
    }
    
    russell.refreshToken(completion)
  }
  
  ///
  /// - Parameters:
  ///   - refreshTokenFailedAfter401Or403Callback: When the plugin received response with status code 401/403, it will try to refresh token. If refresh token got 401/403 response, it will trigger `refreshTokenFailedAfter401Or403Callback`.
  public init(refreshTokenFailedAfter401Or403Callback: @escaping () -> Void) {
    self.refreshTokenFailedAfter401Or403Callback = refreshTokenFailedAfter401Or403Callback
  }
  
  public func didReceive(_ result: Result<Response, QuicksilverError>, target: TargetType) {
    
    func refreshTokenIfNeeded(response: Response) {
      switch response.statusCode {
      case 401, 403:
        guard refreshOn401Or403Lock.try() else { return }
        
        refreshTokenOperation({ error in
          defer { self.refreshOn401Or403Lock.unlock() }
          guard let error = error else { return }
          
          switch error {
          case RussellError.Common.notLoggedIn,
               RussellError.RefreshToken.invalidToken:
            DispatchQueue.main.async(execute: self.refreshTokenFailedAfter401Or403Callback)
          
          case let e as RussellError.Response where e.statusCode == 401:
            DispatchQueue.main.async(execute: self.refreshTokenFailedAfter401Or403Callback)
          default:
            break
          }
        })
        
      default:
        break
      }
    }
    
    switch result {
    case .success(let response),
         .failure(.statusCode(let response)):
      refreshTokenIfNeeded(response: response)
      
    case .failure(.underlying(_, let response)) where response != nil:
      refreshTokenIfNeeded(response: response!)
      
    default:
      return
    }
  }
}

internal final class DefaultParametersPlugin: PluginType {
  
  private let deviceID: String
  private let poolID: String
  private let appID: String
  init(deviceID: String, poolID: String, appID: String) {
    self.deviceID = deviceID
    self.poolID = poolID
    self.appID = appID
  }
  
  var extraParameters: [String: Any]? {
    return [
      "clientPlatform": "IOS",
      "deviceId": deviceID,
      "poolId": poolID
    ]
  }
  
  func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
    var request = request
    // 去除 path 请求中不需要带默认参数
    if let target = target as? DataTargetType, target.path.hasPrefix("http") {
      request.url = URL(string: target.path)
    } else {
      request.setValue(appID, forHTTPHeaderField: "X-App-ID")
    }
    return request
  }
}

internal final class CachePolicyPlugin: PluginType {
  
  func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
    var requestCopy = request
    requestCopy.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    return requestCopy
  }
}
