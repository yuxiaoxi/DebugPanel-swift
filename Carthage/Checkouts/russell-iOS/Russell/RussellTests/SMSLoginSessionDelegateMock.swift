//
//  SMSLoginSessionDelegateMock.swift
//  RussellTests
//
//  Created by Yunfan Cui on 2018/12/25.
//  Copyright © 2018 LLS. All rights reserved.
//

@testable import Russell

final class SMSLoginSessionDelegateMock: SMSLoginSessionDelegate {
  
  var requiresSMSCounter = 0
  
  func sessionRequiresVerificationCode(_ session: CodeVerificationSession) {
    requiresSMSCounter += 1
  }
  
  var loginResult: LoginResult?
  
  func loginSession(_ session: LoginSession, succeededWithResult result: LoginResult) {
    loginResult = result
  }
  
  var failureError: Error?
  
  func loginSession(_ session: LoginSession, failedWithError error: Error) {
    failureError = error
  }
}

final class LoginSessionDelegateMock: OAuthLoginSessionDelegate {
  
  var loginResult: LoginResult?
  
  func loginSession(_ session: LoginSession, succeededWithResult result: LoginResult) {
    loginResult = result
  }
  
  var failureError: Error?
  
  func loginSession(_ session: LoginSession, failedWithError error: Error) {
    failureError = error
  }
  
  func sessionRequiresRealNameCertification(_ session: Session) -> Russell.UI.Container {
    return .presentation(UIViewController())
  }
}
