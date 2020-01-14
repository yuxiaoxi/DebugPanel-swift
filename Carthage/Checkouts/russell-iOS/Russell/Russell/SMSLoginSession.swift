//
//  SMSLoginSession.swift
//  Russell
//
//  Created by Yunfan Cui on 2018/12/11.
//  Copyright © 2018 LLS. All rights reserved.
//

import Foundation

/// 短信验证码登录 Session
public typealias SMSLoginSession = CodeVerificationSession & TwoStepRegistrationLoginSession

public typealias SMSLoginSessionDelegate = CodeVerificationSessionDelegate & TwoStepRegistrationLoginSessionDelegate

// MARK: -

final class _SMSLoginSessionInternal: TwoStepRegistrationLoginSession, CodeVerificationSession {
  
  private weak var delegate: SMSLoginSessionDelegate?
  private var tokenManager: _TokenManagerInternal?
  private let flowWorker: SMSLoginFlowWorker
  private let networkService: NetworkService
  
  private let isSignup: Bool
  
  init(delegate: SMSLoginSessionDelegate, flowWorker: SMSLoginFlowWorker, tokenManager: _TokenManagerInternal, networkService: NetworkService, isSignup: Bool) {
    
    self.delegate = delegate
    self.flowWorker = flowWorker
    self.tokenManager = tokenManager
    self.networkService = networkService
    
    self.isSignup = isSignup
    
    setupWorker()
  }
  
  var codeType: CodeVerificationType { return .sms }
  
  func login(mobile: String) {
    flowWorker.sendVerificationCode(to: mobile)
  }
  
  func verify(code: String) {
    flowWorker.verify(code: code)
  }
  
  func resendVerificationMessage() {
    flowWorker.resendVerificationCode()
  }
  
  private var confirmRegistrationChallenge: ConfirmToRegisterChallenge?
  private lazy var requestWorker = SingleRequestWorker(extraErrorMappings: [RussellError.loginSessionErrorMapping])
  
  func confirmRegistration() {
    guard let challenge = confirmRegistrationChallenge else {
      delegate?.loginSession(self, failedWithError: RussellError.Common.inappropriateUsage)
      return
    }
    
    requestWorker.sendRequest(api: confirmToLogin(challenge), service: networkService) { result in
      switch result {
      case .success(let auth):
        self.tokenManager?.updateToken(auth.result.toToken())
        DispatchQueue.main.async {
          self.delegate?.loginSession(self, succeededWithResult: LoginResult(from: auth.result))
        }
      case .failure(let error):
        DispatchQueue.main.async {
          self.delegate?.loginSession(self, failedWithError: error)
        }
      }
    }
  }
  
  func invalidate() {
    requestWorker.invalidate()
    flowWorker.invalidate()
    
    tokenManager = nil
    delegate = nil
  }
  
  private func setupWorker() {
    
    flowWorker.callbacks.success = { [weak self] result in
      guard let self = self else { return }
      
      switch result {
      case .left(let auth):
        self.tokenManager?.updateToken(auth.result.toToken())
        self.delegate?.loginSession(self, succeededWithResult: LoginResult(from: auth.result))
      case .right(let challenge):
        self.confirmRegistrationChallenge = challenge
        self.delegate?.loginSession(self, requiresUserToConfirmRegistrationWithExtraInfo: challenge.challengeParams)
      }
    }
    
    flowWorker.callbacks.failed = { [weak self] error in
      guard let self = self else { return }
      
      self.delegate?.loginSession(self, failedWithError: error)
    }
    
    flowWorker.callbacks.requiresVerificationCode = { [weak self] _, _, _ in
      guard let self = self else { return }
      
      self.delegate?.sessionRequiresVerificationCode(self)
    }
    
    flowWorker.extraParameters = ["isSignup": isSignup]
  }
  
}

extension _SMSLoginSessionInternal {
  
  func confirmToLogin(_ challenge: ConfirmToRegisterChallenge) -> API<Authentication> {
    return API(method: .post, path: "/api/v2/respond_to_auth_challenge", body: [
      "challenge_type": "CREATE_ACCOUNT",
      "session": challenge.token,
      "poolId": flowWorker.poolID,
      "isSignup": true
      ])
  }
}
