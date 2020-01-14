//
//  OneKeyLoginOAuth.swift
//  Russell
//
//  Created by zhuo yu on 2019/9/10.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit

/// 一键登录OAuth协议
public protocol OneKeyOAuth: OAuth {
  
  var accessToken: String { get }
}

public extension OneKeyOAuth {
  
  var kind: OAuthKind { return .onekey }
  var extraSignature: String { return accessToken }
  /// OAuth 用于请求的二级结构对应的 key
  var parameterKey: String {
    return "oneTapLoginParams"
  }
  /// OAuth 用于请求的二级结构对应的 value
  func parameters(poolID: String, timestampInSec: Int) -> [String: Any] {
    let basicParameters: [String: Any] = [
      "provider": provider,
      "appId": appID,
      "timestampSec": timestampInSec,
      "sig": SignatureGenerator.signatureFrom(poolID: poolID, timestampInSec: timestampInSec, extra: accessToken)
    ]
    return basicParameters.merging(extraParameters, uniquingKeysWith: { _, new in new })
  }
}

/// 一键登录结构体
public struct OneKeyLoginOAuth: OneKeyOAuth {
  
  public let appID: String
  public let accessToken: String
  public var provider: String {
    return "ALIYUN"
  }
  public init(appID: String, accessToken: String) {
    self.appID = appID
    self.accessToken = accessToken
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
