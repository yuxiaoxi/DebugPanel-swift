//
//  LoginSession.swift
//  Russell
//
//  Created by Yunfan Cui on 2018/12/11.
//  Copyright © 2018 LLS. All rights reserved.
//

import Foundation

/// 登录 Session 的抽象 protocol。对应的 `.flow == Flow.login`。
public protocol LoginSession: Session {}

public protocol TwoStepRegistrationLoginSession: LoginSession {
  func confirmRegistration()
}

public extension LoginSession {
  
  var flow: Flow {
    return .login
  }
}

/// 登录成功的结果
public struct LoginResult: Decodable {
  /// neo ID
  public let neoID: String?
  /// 账户 ID
  public let userID: UInt64
  /// 昵称
  public let nick: String?
  /// 头像
  public let avatar: URL?
  /// 是不是新注册用户
  public let isNewRegister: Bool
  /// 用户手机号
  public let mobile: String?
  /// access token
  public let accessToken: String
  /// 用户是否已经设置密码
  public let passwordExists: Bool
  
  enum CodingKeys: String, CodingKey {
    case neoID = "id"
    case userID = "login"
    case nick
    case avatar
    case isNewRegister
    case mobile
    case accessToken
    case passwordExists = "pwdExist"
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    userID = try container.russell_decodeStringUInt64(forKey: .userID)
    
    neoID = try container.decodeIfPresent(String.self, forKey: .neoID)
    
    nick = try container.decodeIfPresent(String.self, forKey: .nick)
    avatar = try container.russell_decodeURLIfPresent(forKey: .avatar)
    isNewRegister = try container.decodeIfPresent(Bool.self, forKey: .isNewRegister) ?? false
    
    mobile = try container.decodeIfPresent(String.self, forKey: .mobile)
    accessToken = try container.decode(String.self, forKey: .accessToken)
    passwordExists = try container.decodeIfPresent(Bool.self, forKey: .passwordExists) ?? false
  }
  
  init(from authResult: Authentication.Result) {
    self.neoID = authResult.neoID
    self.userID = authResult.userID
    self.nick = authResult.nick
    self.avatar = authResult.avatar
    self.isNewRegister = authResult.isNewRegister
    self.mobile = authResult.mobile
    self.accessToken = authResult.accessToken
    self.passwordExists = authResult.passwordExists
  }
}

public protocol LoginSessionDelegate: class {
  
  /// 登录成功的回调
  /// - Note: 所有验证过程全部完成才会回调
  func loginSession(_ session: LoginSession, succeededWithResult result: LoginResult)
  
  /// 登录失败的回调
  /// 错误信息详见[文档](https://git.llsapp.com/common/protos/tree/master/liulishuo/backend/russell/v2#客户端认证-authflow-说明)
  /// - Parameters:
  ///   - session: 当前 login session
  ///   - error: 可能是 `RussellError.Common` `RussellError.LoginSession` `RussellError.Response` 中的一种
  func loginSession(_ session: LoginSession, failedWithError error: Error)
}

public protocol TwoStepRegistrationLoginSessionDelegate: LoginSessionDelegate {
  /// 需要用户手动确认注册
  /// - Note: 收到该回调时，需要经过用户操作确认后，调用 `LoginSession.confirmRegistration()`
  /// - Note: 仅当 pool ID 对应的配置为 “不自动注册用户”，且启动 loginSession 时 `isSignup` 为 `false` 时会触发。
  /// - Note: 为了保持兼容，该方法的默认实现为抛出异常 `RussellError.LoginSession.userNotExist`
  /// - Parameter extraInfo: 其他信息
  func loginSession(_ session: TwoStepRegistrationLoginSession, requiresUserToConfirmRegistrationWithExtraInfo extraInfo: [String: String]?)
}

public extension TwoStepRegistrationLoginSessionDelegate {
  
  func loginSession(_ session: TwoStepRegistrationLoginSession, requiresUserToConfirmRegistrationWithExtraInfo extraInfo: [String: String]?) {
    self.loginSession(session, failedWithError: RussellError.LoginSession.userNotExist)
  }
}

// MARK: - Data

struct Authentication: Decodable {
  
  struct Result: Decodable {
    let accessToken: String
    let expiringDate: Date
    let refreshToken: String
    /// neo ID
    let neoID: String?
    /// 流利号
    let userID: UInt64
    /// 昵称
    let nick: String?
    /// 头像
    let avatar: URL?
    /// 是不是新注册用户
    let isNewRegister: Bool
    /// 用户手机号
    let mobile: String?
    /// 用户是否已经设置密码
    let passwordExists: Bool

    enum CodingKeys: String, CodingKey {
      case accessToken
      case expiringDate = "expiresAtSec"
      case refreshToken
      case neoID = "id"
      case userID = "login"
      case nick
      case avatar
      case isNewRegister
      case mobile
      case passwordExists = "pwdExist"
    }
    
    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      
      accessToken = try container.decode(String.self, forKey: .accessToken)
      
      expiringDate = try container.russell_decodeDate(forKey: .expiringDate)
      
      refreshToken = try container.decode(String.self, forKey: .refreshToken)
      
      userID = try container.russell_decodeStringUInt64(forKey: .userID)
      
      neoID = try container.decodeIfPresent(String.self, forKey: .neoID)
      
      nick = try container.decodeIfPresent(String.self, forKey: .nick)
      avatar = try container.russell_decodeURLIfPresent(forKey: .avatar)
      isNewRegister = try container.decodeIfPresent(Bool.self, forKey: .isNewRegister) ?? false
      mobile = try container.decodeIfPresent(String.self, forKey: .mobile)
      passwordExists = try container.decodeIfPresent(Bool.self, forKey: .passwordExists) ?? false
    }
  }
  
  let result: Result
  enum CodingKeys: String, CodingKey {
    case result = "authenticationResult"
  }
}

extension Authentication.Result {
  func toToken() -> Token {
    return Token(accessToken: accessToken, refreshToken: refreshToken, expiringDate: expiringDate)
  }
}

// MARK: - Confirm to register

struct ConfirmToRegisterChallenge: Decodable {
  let token: String
  let challengeType: String
  let challengeParams: [String: String]?
  
  enum CodingKeys: String, CodingKey {
    case challengeType
    case session
    case challengeParams
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    let type = try container.decode(String.self, forKey: .challengeType)
    guard type == "CREATE_ACCOUNT" else {
      throw DecodingError.dataCorruptedError(forKey: .challengeType, in: container, debugDescription: "unknown challenge type: \(type), should be CREATE_ACCOUNT")
    }
  
    challengeType = type
    token = try container.decode(String.self, forKey: .session)
    
    guard let paramContainer = try? container.nestedContainer(keyedBy: StringCodingKey.self, forKey: .challengeParams) else {
      challengeParams = nil
      return
    }
    challengeParams = paramContainer.allKeys.reduce(into: [:]) {
      $0[$1.stringValue] = try? paramContainer.decode(String.self, forKey: $1)
    }
  }
}

typealias AuthOrConfirmToRegisterChallenge = Either<Authentication, ConfirmToRegisterChallenge>
