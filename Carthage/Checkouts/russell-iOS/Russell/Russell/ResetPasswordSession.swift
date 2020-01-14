//
//  ResetPasswordSession.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/2/20.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

/// 重置密码的 Session。对应的 flow == .resetPassword
public protocol ResetPasswordSession: CodeVerificationSession, Session {
  
  /// 更新 Password
  func setPassword(_ password: String)
}

public extension ResetPasswordSession {
  
  var flow: Flow { return .resetPassword }
}

public protocol ResetPasswordSessionDelegate: CodeVerificationSessionDelegate {
  
  /// 当前 Session 需要用户输入新密码
  func sessionRequiresPassword(_ session: ResetPasswordSession)
  
  /// 重置密码成功
  func session(_ session: ResetPasswordSession, succeededWithResult result: LoginResult)
  
  /// 重置密码过程中出现错误。详见[文档](https://git.llsapp.com/common/protos/tree/master/liulishuo/backend/russell/v2#重置密码)
  func session(_ session: ResetPasswordSession, failedWithError error: Error)
}

final class _ResetPasswordSessionInternal: ResetPasswordSession {
  
  private weak var delegate: ResetPasswordSessionDelegate?
  private let requestWorker = SingleRequestWorker(extraErrorMappings: [RussellError.bindingSessionErrorMapping, RussellError.emailSessionErrorMapping])
  private let flowWorker: ResetPasswordFlowWorker
  private let networkService: NetworkService
  private var tokenManager: _TokenManagerInternal?
  
  var tokenRetriever = { Russell.currentAccessToken }
  
  init(delegate: ResetPasswordSessionDelegate, flowWorker: ResetPasswordFlowWorker, networkService: NetworkService, tokenManager: _TokenManagerInternal) {
    self.delegate = delegate
    self.flowWorker = flowWorker
    self.networkService = networkService
    self.tokenManager = tokenManager
  }
  
  var codeType: CodeVerificationType {
    switch flowWorker.kind {
    case .email:
      return .email
    case .sms, .smsResetPassword, .mobileVerification:
      return .sms
    }
  }
  
  func sendVerificationCode(to account: String) {
    setupWorker()
    flowWorker.sendVerificationCode(to: account)
  }
  
  func verify(code: String) {
    flowWorker.verify(code: code)
  }
  
  func resendVerificationMessage() {
    flowWorker.resendVerificationCode()
  }
  
  func invalidate() {
    requestWorker.invalidate()
    flowWorker.invalidate()
    tokenManager = nil
    delegate = nil
    setPasswordSessionID = nil
  }
  
  func setPassword(_ password: String) {
    guard let sessionID = setPasswordSessionID else { return }
    do {
      try validatePassword(password)
    } catch {
      delegate?.session(self, failedWithError: error)
      return
    }
    
    requestWorker.sendRequest(api: setPasswordAPI(password: password, sessionID: sessionID), service: networkService) { [weak self] (result) in
      guard let self = self else { return }
      
      let delegate = self.delegate
      switch result {
      case .success(let auth):
        self.tokenManager?.updateToken(auth.result.toToken())
        DispatchQueue.main.async {
          delegate?.session(self, succeededWithResult: LoginResult(from: auth.result))
        }
      case .failure(let error):
        DispatchQueue.main.async {
          delegate?.session(self, failedWithError: error)
        }
      }
    }
  }
  
  @inline(__always)
  private func validatePassword(_ password: String) throws {
    if password.count < 6 {
      throw RussellError.SetPassword.passwordTooShort
    }
  }
  
  private var setPasswordSessionID: String?
  
  private func setupWorker() {
    
    flowWorker.callbacks.success = { [weak self] challenge in
      guard let self = self else { return }
      
      self.setPasswordSessionID = challenge.sessionID
      self.delegate?.sessionRequiresPassword(self)
    }
    
    flowWorker.callbacks.failed = { [weak self] error in
      guard let self = self else { return }
      
      self.delegate?.session(self, failedWithError: error)
    }
    
    flowWorker.callbacks.requiresVerificationCode = { [weak self] _, _, _ in
      guard let self = self else { return }
      
      self.delegate?.sessionRequiresVerificationCode(self)
    }
    
    flowWorker.extraParameters = [
      "isSignup": false
    ]
  }
}

private extension _ResetPasswordSessionInternal {
  
  func setPasswordAPI(password: String, sessionID: String) -> API<Authentication> {
    
    let params: [String: Any] = [
      "challengeType": "SET_PASSWORD",
      "session": sessionID,
      "poolId": flowWorker.poolID,
      "pwdResp": ["password": password],
      "isSignup": false
    ]
    
    return API(method: .post, path: "/api/v2/respond_to_auth_challenge", body: params)
  }
}
