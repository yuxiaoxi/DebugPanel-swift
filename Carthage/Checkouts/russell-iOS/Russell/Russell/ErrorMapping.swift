//
//  ErrorMapping.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/8/15.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

// MARK: - Error Translation

extension RussellError {
  
  static func translate(statusCode: Int, serverError: ServerError?, rawError: Error?, extraErrorMappings: [ErrorMapping]) -> Error {
    
    func unknownError() -> Error? {
      return serverError?.message.map { NSError(domain: "Russell", code: 0, userInfo: [NSLocalizedDescriptionKey: $0]) } ?? rawError
    }
    
    guard let serverError = serverError else {
      return RussellError.Response(statusCode: statusCode, rawError: unknownError())
    }
    
    switch (statusCode, serverError.code) {
    // common errors
    case ((500...), 14):
      return Common.serverInternalError
    case (401, 16):
      return Common.notLoggedIn
    case (400, 3),
         (400, 5):
      return Common.clientInternalError
    case (400, 1002):
      return Common.invalidLocalTime
    //
    default:
      for mapping in extraErrorMappings {
        if let error = mapping(serverError.code) {
          return error
        }
      }
      return RussellError.Response(statusCode: statusCode, rawError: unknownError())
    }
  }
}

extension RussellError {
  
  typealias ErrorMapping = (_ serverErrorCode: Int) -> Error?
  
  private static let _smsSessionErrorMap: [Int: SMS] = [
    1003: .smsAlreadySent,
    1004: .requiresSMSTooFrequently,
    1005: .invalidMobile,
    1010: .invalidSMSCode,
    1011: .expiredSMSCode
  ]
  static func smsSessionErrorMapping(serverErrorCode: Int) -> Error? {
    return _smsSessionErrorMap[serverErrorCode]
  }
  
  private static let _loginSessionErrorMap: [Int: LoginSession] = [
    16: .incorrectPassword,
    1001: .userNotExist,
    1006: .blockedByPoolRule,
    1012: .userAlreadyExists
  ]
  static func loginSessionErrorMapping(serverErrorCode: Int) -> Error? {
    return _loginSessionErrorMap[serverErrorCode]
  }
  
  private static let _bindingSessionErrorMap: [Int: Binding] = [
    16: .notLoggedIn,
    1102: .mobileAlreadyBound,
    1103: .emailAlreadyBound,
    1110: .oauthAlreadyBoundByOthers,
    1112: .accountAlreadyBoundOAuth
  ]
  static func bindingSessionErrorMapping(serverErrorCode: Int) -> Error? {
    return _bindingSessionErrorMap[serverErrorCode]
  }
  
  private static let _refreshTokenErrorMap: [Int: RefreshToken] = [
    1200: .unnecessaryRefreshRequest,
    1201: .invalidToken
  ]
  static func refreshTokenErrorMapping(serverErrorCode: Int) -> Error? {
    return _refreshTokenErrorMap[serverErrorCode]
  }
  
  private static let _emailSessionErrorMap: [Int: Email] = [
    1003: .emailAlreadySent,
    1004: .requiresEmailTooFrequently,
    1008: .invalidEmail,
    1010: .invalidEmailCode,
    1011: .expiredEmailCode
  ]
  static func emailSessionErrorMapping(serverErrorCode: Int) -> Error? {
    return _emailSessionErrorMap[serverErrorCode]
  }
  
  private static let _setPasswordErrorMap = [1009: SetPassword.passwordTooShort]
  static func setPasswordErrorMapping(serverErrorCode: Int) -> Error? {
    return _setPasswordErrorMap[serverErrorCode]
  }
  
  private static let _updatePasswordErrorMap: [Int: UpdatePassword] = [
    16: .notLoggedIn,
    1104: .authorizationFailure,
    1009: .passwordTooShort,
    1019: .passwordInvalid,
    1018: .oldPasswordIncorrect,
    1014: .operationTooFrequently
  ]
  static func updatePasswordErrorMapping(serverErrorCode: Int) -> Error? {
    return _updatePasswordErrorMap[serverErrorCode]
  }
  
  private static let _realNameVerificationErrorMap: [Int: RealNameVerification] = [
    1203: .weekBindExceeded,
    1204: .sessionExpired,
    1202: .pleaseUseMobileToLogin
  ]
  static func realNameVerificationErrorMapping(serverErrorCode: Int) -> Error? {
    return _realNameVerificationErrorMap[serverErrorCode]
  }
}

// MARK: - Reverse Error Code

protocol RussellErrorCodeRepresentable {
  var russellErrorCode: Int? { get }
}

extension RussellError.Common: RussellErrorCodeRepresentable {
  
  var russellErrorCode: Int? {
    switch self {
    case .serverInternalError:
      return 14
    case .notLoggedIn:
      return 16
    case .clientInternalError:
      return 3
    case .invalidLocalTime:
      return 1002
    default:
      return nil
    }
  }
}

private extension Dictionary where Value: Equatable {
  
  func russell_key(of value: Value) -> Key? {
    return first(where: { $0.value == value })?.key
  }
}

extension RussellError.SMS: RussellErrorCodeRepresentable {
  
  var russellErrorCode: Int? {
    return RussellError._smsSessionErrorMap.russell_key(of: self)
  }
}

extension RussellError.LoginSession: RussellErrorCodeRepresentable {
  
  var russellErrorCode: Int? {
    return RussellError._loginSessionErrorMap.russell_key(of: self)
  }
}

extension RussellError.Binding: RussellErrorCodeRepresentable {
  
  var russellErrorCode: Int? {
    return RussellError._bindingSessionErrorMap.russell_key(of: self)
  }
}

extension RussellError.RefreshToken: RussellErrorCodeRepresentable {
  
  var russellErrorCode: Int? {
    return RussellError._refreshTokenErrorMap.russell_key(of: self)
  }
}

extension RussellError.Email: RussellErrorCodeRepresentable {
  
  var russellErrorCode: Int? {
    return RussellError._emailSessionErrorMap.russell_key(of: self)
  }
}

extension RussellError.SetPassword: RussellErrorCodeRepresentable {
  
  var russellErrorCode: Int? {
    return RussellError._setPasswordErrorMap.russell_key(of: self)
  }
}

extension RussellError.UpdatePassword: RussellErrorCodeRepresentable {
  
  var russellErrorCode: Int? {
    return RussellError._updatePasswordErrorMap.russell_key(of: self)
  }
}

extension RussellError.RealNameVerification: RussellErrorCodeRepresentable {
  
  var russellErrorCode: Int? {
    return RussellError._realNameVerificationErrorMap.russell_key(of: self)
  }
}
