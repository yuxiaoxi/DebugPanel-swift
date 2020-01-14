//
//  OneKeyBinderOAuth.swift
//  Russell
//
//  Created by zhuo yu on 2019/10/24.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit

// 一键绑定OAuth协议
public protocol OneBinderOAuth: OAuth {
  
  var accessToken: String { get }
}

public extension OneBinderOAuth {
  
  var kind: OAuthKind { return .onekeybinder }
  var extraSignature: String { return accessToken }
  /// OAuth 用于请求的二级结构对应的 key
  var parameterKey: String {
    return "oneTapParams"
  }
  /// OAuth 用于请求的二级结构对应的 value
  func parameters(poolID: String, timestampInSec: Int) -> [String: Any] {
    let basicParameters: [String: Any] = [
      "provider": provider
    ]
    return basicParameters.merging(extraParameters, uniquingKeysWith: { _, new in new })
  }
}

/// 一键绑定结构体
public struct OneKeyBinderOAuth: OneBinderOAuth {
  public var appID: String
  
  public let accessToken: String
  public var provider: String {
    return "ALIYUN"
  }
  public init(accessToken: String) {
    self.accessToken = accessToken
    self.appID = ""
  }
  
  public var extraParameters: [String: Any] {
    return [
      "aliyunParams": [
        "accessToken": accessToken,
        "outid": "123456"
      ]
    ]
  }
  
}
