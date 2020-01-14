//
//  BindMobileSession.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/1/2.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

/// 绑定手机号 Session
public typealias BindMobileSession = CodeVerificationSession & BindSession

public typealias BindMobileSessionDelegate = CodeVerificationSessionDelegate & BindSessionDelegate

// MARK: -

final class _BindMobileSessionInternal: BindSession, CodeVerificationSession {
  
  private weak var delegate: BindMobileSessionDelegate?
  private let flowWorker: BindMobileFlowWorker
  
  var tokenRetriever = { Russell.currentAccessToken }
  
  init(delegate: BindMobileSessionDelegate, flowWorker: BindMobileFlowWorker) {
    
    self.delegate = delegate
    self.flowWorker = flowWorker
  }
  
  var codeType: CodeVerificationType {
    return .sms
  }
  
  func bind(mobile: String) {
    
    setupWorker()
    flowWorker.sendVerificationCode(to: mobile)
  }
  
  func verify(code: String) {
    flowWorker.verify(code: code)
  }
  
  func resendVerificationMessage() {
    flowWorker.resendVerificationCode()
  }
  
  func invalidate() {
    flowWorker.invalidate()
    
    delegate = nil
  }
  
  private func setupWorker() {
    
    flowWorker.callbacks.success = { [weak self] auth in
      guard let self = self else { return }
      
      self.delegate?.sessionSucceeded(self)
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
