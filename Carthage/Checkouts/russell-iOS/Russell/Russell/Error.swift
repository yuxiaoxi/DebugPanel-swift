//
//  Error.swift
//  Russell
//
//  Created by Yunfan Cui on 2018/12/11.
//  Copyright © 2018 LLS. All rights reserved.
//

import Foundation

public enum RussellError {}

// MARK: - Common Error

extension RussellError {
  
  public enum Common: String, RussellLocalizedError {
    /// 服务器内部错误
    case serverInternalError
    /// Russell 内部错误
    case clientInternalError
    /// 网络错误
    case networkError
    /// 当前 Session 已废弃
    case sessionInvalidated
    /// 系统本地时间和服务器时间差距过大
    case invalidLocalTime
    /// 请求被 cancel
    case canceled
    /// 未知错误
    case unknown
    /// 使用不当
    case inappropriateUsage
    /// 用户未登录
    case notLoggedIn
  }
}

// MARK: - SMS Error

extension RussellError {
  
  public enum SMS: String, RussellLocalizedError {
    /// 验证码已发送，请一分钟后重试
    case smsAlreadySent
    /// 获取验证码过于频繁
    case requiresSMSTooFrequently
    /// 手机号码格式有误
    case invalidMobile
    /// 短信验证码错误
    case invalidSMSCode
    /// 验证码已失效，需要重新获取
    case expiredSMSCode
  }
}

// MARK: - Email Error

extension RussellError {
  
  public enum Email: String, RussellLocalizedError {
    /// 验证码已发送，请一分钟后重试
    case emailAlreadySent
    /// 获取验证码过于频繁
    case requiresEmailTooFrequently
    /// 邮箱格式有误
    case invalidEmail
    /// 邮箱验证码错误
    case invalidEmailCode
    /// 验证码已失效，需要重新获取
    case expiredEmailCode
  }
}

// MARK: - Login Session Error

extension RussellError {
  
  public enum LoginSession: String, RussellLocalizedError {
    
    public static var allCases: [RussellError.LoginSession] {
      return [.captchaError, .userNotExist, .blockedByPoolRule, .incorrectPassword]
    }
    
    /// 第三方验证码失败
    case captchaError
    
    // - response errors from server
    
    /// 用户不存在
    case userNotExist
    /// 违反 pool 策略
    case blockedByPoolRule
    /// (Deprecated) 该账户已注册，请直接登录
    @available(*, deprecated, message: "已注册用户在使用 isSignup: true 参数时，不会再收到\"该账户已注册\"的错误信息了")
    case userAlreadyExists
    /// 密码错误
    case incorrectPassword
  }
}

// MARK: - Binding Error

extension RussellError {
  
  public enum Binding: String, RussellLocalizedError {
    /// 用户尚未登录
    case notLoggedIn
    /// 手机号已被绑定
    case mobileAlreadyBound
    /// 第三方账号已经被绑定
    case oauthAlreadyBoundByOthers
    /// 该账号已绑定这个第三方账号
    case accountAlreadyBoundOAuth
    /// 邮箱已被绑定
    case emailAlreadyBound
  }
}

// MARK: - Set Password

extension RussellError {
  
  public enum SetPassword: String, RussellLocalizedError {
    /// 密码需要 8 位以上
    case passwordTooShort
    /// 密码需同时包含字母和数字
    case passwordInvalid
  }
}

// MARK: - Update Password

extension RussellError {
  
  public enum UpdatePassword: String, RussellLocalizedError {
    /// 用户未登录
    case notLoggedIn
    /// 认证失败
    case authorizationFailure
    /// 密码需不少于 8 位
    case passwordTooShort
    /// 密码需同时包含字母和数字
    case passwordInvalid
    /// 原密码错误
    case oldPasswordIncorrect
    /// 操作过于频繁
    case operationTooFrequently
  }
}

// MARK: - User Info

extension RussellError {
  
  public enum UserInfo: Error {
    /// 用户未登录
    case notLoggedIn
    /// 请求错误
    case other(Error)
  }
}

// MARK: - Real Name Verification

extension RussellError {
  
  public enum RealNameVerification: String, RussellLocalizedError {
    /// 当前手机号相关弱绑定账号过多
    case weekBindExceeded
    /// 当前绑定流程已失效，须重新登录
    case sessionExpired
    /// 用户的第三方帐号未注册，并且手机号已经有绑定对应帐号
    case pleaseUseMobileToLogin
    /// 用户已取消实名认证
    case canceled
  }
}

// MARK: - Response Error

extension RussellError {
  
  public struct Response: LocalizedError {
    public let statusCode: Int
    public let rawError: Error?
    
    public var errorDescription: String? {
      return rawError?.localizedDescription ?? String(format: Localization.string(for: "RussellError-Response-invalidStatus"), statusCode)
    }
  }
}

// MARK: - Refresh Token Error

extension RussellError {
  
  /// Refresh Token 可能返回的错误
  ///
  /// - unnecessaryRefreshRequest: 当前 token 尚可使用，不必刷新
  /// - invalidToken: 当前 token 无效
  public enum RefreshToken: String, RussellLocalizedError {
    
    case unnecessaryRefreshRequest
    
    case invalidToken
  }
}

public extension RussellError.RefreshToken {
  
  @available(*, deprecated, message: "请使用 RussellError.Common.notLoggedIn")
  static let notLoggedIn = RussellError.Common.notLoggedIn
}
