//
//  BindEmailSession.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/2/19.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

public protocol BindEmailSession: CodeVerificationSession, BindSession {
  
  func setPassword(_ password: String)
}

public protocol BindEmailSessionDelegate: CodeVerificationSessionDelegate, BindSessionDelegate {
  
  func sessionRequiresPassword(_ session: BindEmailSession)
}

final class _BindEmailSessionInternal: BindEmailSession {
  
  private weak var delegate: BindEmailSessionDelegate?
  private let requestWorker = SingleRequestWorker(extraErrorMappings: [RussellError.bindingSessionErrorMapping, RussellError.emailSessionErrorMapping])
  private let flowWorker: BindEmailFlowWorker
  private let networkService: NetworkService
  
  var tokenRetriever = { Russell.currentAccessToken }
  
  init(delegate: BindEmailSessionDelegate, flowWorker: BindEmailFlowWorker, networkService: NetworkService) {
    self.delegate = delegate
    self.flowWorker = flowWorker
    self.networkService = networkService
  }
  
  var codeType: CodeVerificationType {
    return .email
  }
  
  func sendEmail(to email: String) {
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
  
  func setPassword(_ password: String) {
    guard let sessionID = setPasswordSessionID else { return }
    
    guard password.count >= 6 else {
      delegate?.session(self, failedWithError: RussellError.SetPassword.passwordTooShort)
      return
    }
    requestWorker.sendRequest(api: setPasswordAPI(password: password, sessionID: sessionID), service: networkService) { [weak self] (result) in
      guard let self = self else { return }
      
      let delegate = self.delegate
      switch result {
      case .success:
        DispatchQueue.main.async {
          delegate?.sessionSucceeded(self)
        }
      case .failure(let error):
        DispatchQueue.main.async {
          delegate?.session(self, failedWithError: error)
        }
      }
    }
  }
  
  private var setPasswordSessionID: String?
  
  private func setupWorker() {
    
    flowWorker.callbacks.success = { [weak self] session in
      guard let self = self else { return }
      
      self.setPasswordSessionID = session.id
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
      "isSignup": false,
      "token": tokenRetriever() ?? ""
    ]
  }
}

private extension _BindEmailSessionInternal {
  
  func setPasswordAPI(password: String, sessionID: String) -> API<Void> {
    
    let params = [
      "token": tokenRetriever() ?? "",
      "session": sessionID,
      "password": password
    ]
    
    return API(method: .post, path: "/api/v2/set_password", body: params)
  }
}
