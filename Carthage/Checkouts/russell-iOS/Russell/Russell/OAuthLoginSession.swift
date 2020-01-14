//
//  OAuthLoginSession.swift
//  Russell
//
//  Created by Yunfan Cui on 2018/12/11.
//  Copyright © 2018 LLS. All rights reserved.
//

import Foundation

public typealias OAuthLoginSessionDelegate = TwoStepRegistrationLoginSessionDelegate & RealNameCertificationSessionDelegate

/// 第三方登录 Session
public final class OAuthLoginSession<OAuthType: OAuth>: TwoStepRegistrationLoginSession {
  
  private let auth: OAuthType
  private let poolID: String
  private let isSignup: Bool
  private weak var delegate: OAuthLoginSessionDelegate?
  private let privacyInfo: PrivacyInfo
  init(auth: OAuthType, poolID: String, delegate: OAuthLoginSessionDelegate, isSignup: Bool, privacyInfo: PrivacyInfo) {
    self.auth = auth
    self.poolID = poolID
    self.isSignup = isSignup
    self.delegate = delegate
    self.privacyInfo = privacyInfo
  }
  
  private let requestWorker = SingleRequestWorker(extraErrorMappings: [RussellError.loginSessionErrorMapping])
  private var networkService: NetworkService?
  private var tokenManager: _TokenManagerInternal?
  
  private var confirmRegistrationChallenge: ConfirmToRegisterChallenge?
  
  public func confirmRegistration() {
    guard let challenge = confirmRegistrationChallenge,
      let networkService = networkService
      else {
        delegate?.loginSession(self, failedWithError: RussellError.Common.inappropriateUsage)
        return
    }
    
    requestWorker.sendRequest(api: confirmToLogin(challenge), service: networkService) { result in
      switch result {
      case .success(let auth):
        self.confirmRegistrationChallenge = nil
        self._handleLoginSucceeded(auth)
      case .failure(let error):
        DispatchQueue.main.async {
          self.delegate?.loginSession(self, failedWithError: error)
        }
      }
    }
  }
  
  public func invalidate() {
    requestWorker.invalidate()
  }
  
  @discardableResult func run(networkService: NetworkService, tokenManager: _TokenManagerInternal) -> OAuthLoginSession<OAuthType> {
    self.networkService = networkService
    self.tokenManager = tokenManager
    
    requestWorker.sendRequest(api: loginAPI(), service: networkService) { result in
      
      switch result {
      case .success(let response):
        switch response {
        case .left(let auth):
          self._handleLoginSucceeded(auth)
          
        case .right(.left(let challenge)):
          self.confirmRegistrationChallenge = challenge
          DispatchQueue.main.async {
            self.delegate?.loginSession(self, requiresUserToConfirmRegistrationWithExtraInfo: challenge.challengeParams)
          }
          
        case .right(.right(let challenge)):
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
  
  private func _handleLoginSucceeded(_ auth: Authentication) {
    tokenManager?.updateToken(auth.result.toToken())
    DispatchQueue.main.async {
      self.delegate?.loginSession(self, succeededWithResult: LoginResult(from: auth.result))
    }
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

extension OAuthLoginSession {
  
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
        self._handleLoginSucceeded(auth)
      } else if let error = error {
        self.delegate?.loginSession(self, failedWithError: error)
      } else {
        self.delegate?.loginSession(self, failedWithError: RussellError.RealNameVerification.canceled)
      }
    }
  }
}

private extension OAuthLoginSession {
  /// 第三方登录 API
  func loginAPI() -> API<Either<Authentication, Either<ConfirmToRegisterChallenge, MobileVerificationChanllenge>>> {
    return API(method: .post, path: "/api/v2/initiate_auth", body: [
      "authFlow": auth.kind.flow,
      "poolId": poolID,
      auth.parameterKey: auth.parameters(poolID: poolID, timestampInSec: Int(Date().timeIntervalSince1970)),
      "isSignup": isSignup
    ])
  }
  
  func confirmToLogin(_ challenge: ConfirmToRegisterChallenge) -> API<Authentication> {
    return API(method: .post, path: "/api/v2/respond_to_auth_challenge", body: [
      "challenge_type": "CREATE_ACCOUNT",
      "session": challenge.token,
      "poolId": poolID,
      "isSignup": true
    ])
  }
}
