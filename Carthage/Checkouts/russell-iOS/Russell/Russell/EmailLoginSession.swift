//
//  EmailLoginSession.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/3/25.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

public protocol EmailRegisterSession: CodeVerificationSession, TwoStepRegistrationLoginSession {
  
  func setPassword(_ password: String)
}

public protocol EmailRegisterSessionDelegate: CodeVerificationSessionDelegate, TwoStepRegistrationLoginSessionDelegate {
  
  func sessionRequiresPassword(_ session: EmailRegisterSession)
}

final class _EmailRegisterSessionInternal: EmailRegisterSession {
  
  private weak var delegate: EmailRegisterSessionDelegate?
  private let requestWorker = SingleRequestWorker(extraErrorMappings: [RussellError.loginSessionErrorMapping, RussellError.setPasswordErrorMapping])
  private let flowWorker: EmailRegisterSessionFlowWorker
  private let networkService: NetworkService
  
  var tokenRetriever = { Russell.currentAccessToken }
  
  init(delegate: EmailRegisterSessionDelegate, flowWorker: EmailRegisterSessionFlowWorker, networkService: NetworkService) {
    self.delegate = delegate
    self.flowWorker = flowWorker
    self.networkService = networkService
  }
  
  var codeType: CodeVerificationType {
    return .email
  }
  
  func login(email: String) {
    setupWorker()
    flowWorker.sendVerificationCode(to: email)
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
    delegate = nil
    setPasswordSessionID = nil
  }
  
  func confirmRegistration() {
    guard let token = confirmRegistrationToken else {
      delegate?.loginSession(self, failedWithError: RussellError.Common.inappropriateUsage)
      return
    }
    
    requestWorker.sendRequest(api: confirmToLogin(token), service: networkService) { result in
      switch result {
      case .success(let challenge):
        DispatchQueue.main.async {
          self.requireExternalPassword(challenge.sessionID)
        }
      case .failure(let error):
        DispatchQueue.main.async {
          self.delegate?.loginSession(self, failedWithError: error)
        }
      }
    }
  }
  
  func setPassword(_ password: String) {
    guard let sessionID = setPasswordSessionID else { return }
    
    guard password.count >= 6 else {
      delegate?.loginSession(self, failedWithError: RussellError.SetPassword.passwordTooShort)
      return
    }
    
    requestWorker.sendRequest(api: setPasswordAPI(password: password, sessionID: sessionID), service: networkService) { [weak self] (result) in
      guard let self = self else { return }
      
      let delegate = self.delegate
      switch result {
      case .success(let value):
        DispatchQueue.main.async {
          delegate?.loginSession(self, succeededWithResult: LoginResult(from: value.result))
        }
      case .failure(let error):
        DispatchQueue.main.async {
          delegate?.loginSession(self, failedWithError: error)
        }
      }
    }
  }
  
  // MARK: - private
  
  private var confirmRegistrationToken: String?
  private var setPasswordSessionID: String?
  
  private func setupWorker() {
    
    flowWorker.callbacks.success = { [weak self] session in
      guard let self = self else { return }
      
      switch session {
      case .left(let challenge):
        self.requireExternalPassword(challenge.sessionID)
      case .right(let challenge):
        self.requireUserConfirmRegistration(challenge)
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
    
    flowWorker.extraParameters = [
      "isSignup": true
    ]
  }
  
  private func requireUserConfirmRegistration(_ challenge: ConfirmToRegisterChallenge) {
    confirmRegistrationToken = challenge.token
    delegate?.loginSession(self, requiresUserToConfirmRegistrationWithExtraInfo: challenge.challengeParams)
  }
  
  private func requireExternalPassword(_ sessionID: String) {
    setPasswordSessionID = sessionID
    delegate?.sessionRequiresPassword(self)
  }
}

private extension _EmailRegisterSessionInternal {
  
  func setPasswordAPI(password: String, sessionID: String) -> API<Authentication> {
    
    let params: [String: Any] = [
      "challengeType": "SET_PASSWORD",
      "pwdResp": [
        "password": password
      ],
      "poolId": flowWorker.poolID,
      "session": sessionID,
      "isSignup": true
    ]
    
    return API(method: .post, path: "/api/v2/respond_to_auth_challenge", body: params)
  }
  
  func confirmToLogin(_ token: String) -> API<SetPasswordChallenge> {
    return API(method: .post, path: "/api/v2/respond_to_auth_challenge", body: [
      "challenge_type": "CREATE_ACCOUNT",
      "session": token,
      "poolId": flowWorker.poolID,
      "isSignup": true
      ])
  }
}
