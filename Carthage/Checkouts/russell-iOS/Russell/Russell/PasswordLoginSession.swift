//
//  PasswordLoginSession.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/1/2.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

public typealias PasswordLoginSessionDelegate = RealNameCertificationSessionDelegate & LoginSessionDelegate

public final class PasswordLoginSession: LoginSession {
  
  private let poolID: String
  private let account: String
  private let password: String
  private let isSignup: Bool
  private let privacyInfo: PrivacyInfo
  private weak var delegate: PasswordLoginSessionDelegate?
  private var tokenManager: _TokenManagerInternal?
  
  init(poolID: String, account: String, password: String, delegate: PasswordLoginSessionDelegate, isSignup: Bool, privacyInfo: PrivacyInfo) {
    self.poolID = poolID
    self.account = account
    self.password = password
    self.delegate = delegate
    self.isSignup = isSignup
    self.privacyInfo = privacyInfo
  }
  
  private let requestWorker = SingleRequestWorker(extraErrorMappings: [RussellError.loginSessionErrorMapping])
  
  public func invalidate() {
    requestWorker.invalidate()
  }
  
  @discardableResult func run(networkService: NetworkService, tokenManager: _TokenManagerInternal) -> PasswordLoginSession {
    requestWorker.sendRequest(api: loginAPI(), service: networkService) { result in
      self.tokenManager = tokenManager
      switch result {
      case .success(let response):
        switch response {
        case .left(let auth):
          tokenManager.updateToken(auth.result.toToken())
          DispatchQueue.main.async {
            self.delegate?.loginSession(self, succeededWithResult: LoginResult(from: auth.result))
          }
        case .right(let challenge):
          DispatchQueue.main.async {
            self._prepareRealNameCertification(sessionID: challenge.session, challengeType: challenge.challengeType, isNewRegister: challenge.challengeInfo?.isNewRegister == true)
          }
        }
        
      case .failure(let error):
        DispatchQueue.main.async {
          self.delegate?.loginSession(self, failedWithError: error)
        }
      }
    }
    
    return self
  }
  
  /// 展示升级到一键绑定后的实名认证流程
  ///
  /// - Parameters:
  ///   - sessionID: VERIFY_MOBILE challenge session
  ///   - isNewRegister: 打点用数据，表示当前流程是否为注册流程
  private func _prepareRealNameCertification(sessionID: String, challengeType: String, isNewRegister: Bool) {
    guard let delegate = delegate else { return }
    let container = delegate.sessionRequiresRealNameCertification(self)
    
    guard challengeType == BinderChallengeType else {
      return openRealNameCertificate(container, sessionID, isNewRegister, false, isNewRegister ? .newRegister : .signIn)
    }
    
    guard Russell.OneKeyLoginFlow.privacyInfo != nil else {
      return openRealNameCertificate(container, sessionID, isNewRegister, false, isNewRegister ? .newRegister : .signIn)
    }
    
    Russell.UI._showOneKeyBinder(in: container, session: sessionID, isSignup: isNewRegister, delegate: delegate, binderBlock: self.openRealNameCertificate(_:_:_:_:_:))
  }
  
}

extension PasswordLoginSession {
  
  /// 展示默认的实名认证流程
  /// - Parameter sessionID: VERIFY_MOBILE challenge session
  /// - Parameter isNewRegister: 打点用数据，表示当前流程是否为注册流程
  func openRealNameCertificate(_ container: Russell.UI.Container, _ sessionID: String, _ isNewRegister: Bool, _ canBack: Bool, _ source: BindMobileTracking.Source) {
    guard let delegate = delegate else { return }
    var configuration = BindMobileConfiguration(privacyInfo: self.privacyInfo, isRebinding: false, isExpired: false, requiresToken: false, session: sessionID)
    configuration.isFromLogin = isNewRegister
    configuration.automaticallyDismissesRealNameUIAfterFinished = delegate.sessionShouldAutomaticallyDismissRealNameCertificationUI(self)
    let tracking = BindMobileTracking(source: source, currentMobileStatus: .none)
    Russell.UI._realNameCertificate(in: container, session: sessionID, configuration: configuration, tracking: tracking, canBack: canBack) { auth, error in
      if let auth = auth {
        self.tokenManager?.updateToken(auth.result.toToken())
        DispatchQueue.main.async {
          delegate.loginSession(self, succeededWithResult: LoginResult(from: auth.result))
        }
      } else if let error = error {
        self.delegate?.loginSession(self, failedWithError: error)
      } else {
        self.delegate?.loginSession(self, failedWithError: RussellError.RealNameVerification.canceled)
      }
    }
  }
}

private extension PasswordLoginSession {
  /// 密码登录
  func loginAPI() -> API<Either<Authentication, MobileVerificationChanllenge>> {
    let time = Int(Date().timeIntervalSince1970)
    return API(method: .post, path: "/api/v2/initiate_auth", body: [
      "authFlow": "LOGIN_BY_PWD",
      "poolId": poolID,
      "pwdParams": [
        "uid": account,
        "pwd": password,
        "timestampSec": time,
        "sig": SignatureGenerator.signatureFrom(poolID: poolID, timestampInSec: time, extra: password)
      ],
      "isSignup": isSignup
    ])
  }
}
