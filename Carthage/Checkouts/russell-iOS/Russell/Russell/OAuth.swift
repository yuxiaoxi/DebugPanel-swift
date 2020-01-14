//
//  OAuth.swift
//  Russell
//
//  Created by Yunfan Cui on 2018/12/18.
//  Copyright © 2018 LLS. All rights reserved.
//

import Foundation

/// 第三方登录的种类。
///
/// - code: 对应 Russell 的 [OAuthAuthCode](https://git.llsapp.com/common/protos/blob/master/liulishuo/backend/russell/v2/common.proto#L70)
/// - implicit: 对应 Russell 的 [OAuthImplicit](https://git.llsapp.com/common/protos/blob/master/liulishuo/backend/russell/v2/common.proto#L54)
public enum OAuthKind: String {
  case code = "Code"
  case implicit = "Implicit"
  case onekey = "OneKey"
  case onekeybinder = "onekeybinder"
  
  var flow: String {
    switch self {
    case .code:
      return "OAUTH_AUTH_CODE"
    case .implicit:
      return "OAUTH_IMPLICIT"
    case .onekey:
      return "MOBILE_ONE_TAP_LOGIN"
    case .onekeybinder:
      return "ONETAP_VERIFY_MOBILE"
    }
  }
}

/// 第三方登录鉴权的抽象协议
public protocol OAuth {
  /// 第三方登录种类
  var kind: OAuthKind { get }
  /// 第三方登录服务的提供方
  var provider: String { get }
  /// 当前 App 在第三方服务注册的 App ID
  var appID: String { get }
  /// 额外用于生成请求签名的字符串，详见[文档](https://git.llsapp.com/common/protos/tree/master/liulishuo/backend/russell/v2)中关于 sig 的描述。
  var extraSignature: String { get }
  /// 额外的鉴权参数。如微信的 "code"，QQ 的 "uid" 和 "accessToken"
  var extraParameters: [String: Any] { get }
}

extension OAuth {
  /// OAuth 用于请求的二级结构对应的 key
  var parameterKey: String {
    return "oauth\(kind.rawValue)Params"
  }
  
  /// OAuth 用于请求的二级结构对应的 value
  func parameters(poolID: String, timestampInSec: Int) -> [String: Any] {
    let basicParameters: [String: Any] = [
      "provider": provider,
      "appId": appID,
      "timestampSec": timestampInSec,
      "sig": SignatureGenerator.signatureFrom(poolID: poolID, timestampInSec: timestampInSec, extra: extraSignature)
    ]
    return basicParameters.merging(extraParameters, uniquingKeysWith: { _, new in new })
  }
}

// MARK: - Code OAuth

/// [OAuthAuthCode](https://git.llsapp.com/common/protos/blob/master/liulishuo/backend/russell/v2/common.proto#L70) 类型的第三方登录鉴权
public protocol CodeOAuth: OAuth {
  
  var code: String { get }
}

public extension CodeOAuth {
  
  var kind: OAuthKind { return .code }
  
  var extraSignature: String { return code }
  
  var extraParameters: [String: Any] {
    return ["code": code]
  }
}

// MARK: - Implicit OAuth

/// [OAuthImplicit](https://git.llsapp.com/common/protos/blob/master/liulishuo/backend/russell/v2/common.proto#L54) 类型的第三方登录鉴权
public protocol ImplicitOAuth: OAuth {
  
  var accessToken: String { get }
  
  var uID: String { get }
}

public extension ImplicitOAuth {
  
  var kind: OAuthKind { return .implicit }
  
  var extraSignature: String { return accessToken }
  
  var extraParameters: [String: Any] {
    return [
      "uid": uID,
      "accessToken": accessToken
    ]
  }
}

// MARK: - Common OAuth

/// 默认的微信登录鉴权
public struct WechatAuth: CodeOAuth {
  
  public let appID: String
  public let code: String
  
  public init(appID: String, code: String) {
    self.appID = appID
    self.code = code
  }
  
  public var provider: String {
    return "WECHAT"
  }
}

/// 默认的 QQ 登录鉴权
public struct QQAuth: ImplicitOAuth {
  
  public let appID: String
  public let accessToken: String
  public let uID: String
  
  public init(appID: String, accessToken: String, uID: String) {
    self.appID = appID
    self.accessToken = accessToken
    self.uID = uID
  }
  
  public var provider: String {
    return "QQ"
  }
}

/// 默认的微博登录鉴权
public struct WeiboAuth: ImplicitOAuth {
  public let appID: String
  public let accessToken: String
  public let uID: String
  
  public init(appID: String, accessToken: String, uID: String) {
    self.appID = appID
    self.accessToken = accessToken
    self.uID = uID
  }
  
  public var provider: String {
    return "WEIBO"
  }
}

/// 默认的Apple登录鉴权
public struct AppleAuth: CodeOAuth {
  public let appID: String
  public let code: String
  public let appleUserInfo: AppleUserInfo
  
  public init(appID: String, code: String, appleUserInfo: AppleUserInfo) {
    self.appID = appID
    self.code = code
    self.appleUserInfo = appleUserInfo
  }
  
  public var provider: String {
    return "APPLE"
  }
  
  public var extraParameters: [String: Any] {
    return [
      "appleUserInfo": [
        "firstName": appleUserInfo.firstName,
        "lastName": appleUserInfo.lastName,
        "email": appleUserInfo.email
      ],
      "code": code
    ]
  }
  
  public var extraSignature: String {
    return code
  }
}

///苹果用户信息
public struct AppleUserInfo {
  public let firstName: String
  public let lastName: String
  public let email: String
  
  public init(firstName: String, lastName: String, email: String) {
    self.firstName = firstName
    self.lastName = lastName
    self.email = email
  }
}
