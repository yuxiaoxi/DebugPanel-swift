//
//  OneKeyBinderSession.swift
//  Russell
//
//  Created by zhuo yu on 2019/10/24.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit

/// 一键绑定 challengeType
public let BinderChallengeType = "ONETAP_VERIFY_MOBILE"

public typealias OneKeyBinderSessionDelegate = RealNameCertificationSessionDelegate & LoginSessionDelegate

protocol TwoStepOneKeyBinderSession: LoginSession {
  func popConfirmBinder(_ challenge: MobileVerificationChanllenge)
}

public class OneKeyBinderSession<OAuthType: OAuth>: LoginSession, HeadsUpDisplayable {
  
  private let auth: OAuthType
  private let poolID: String
  private let sessionID: String
  private let isSignup: Bool
  private weak var delegate: OneKeyBinderSessionDelegate?
  private let fromViewController: UIViewController
  
  init(auth: OAuthType, poolID: String, sessionID: String, isSignup: Bool, delegate: OneKeyBinderSessionDelegate, fromViewController: UIViewController) {
    self.auth = auth
    self.poolID = poolID
    self.sessionID = sessionID
    self.isSignup = isSignup
    self.delegate = delegate
    self.fromViewController = fromViewController
  }

  private let requestWorker = SingleRequestWorker(extraErrorMappings: [RussellError.bindingSessionErrorMapping, RussellError.realNameVerificationErrorMapping])
  private var networkService: NetworkService?
  private var tokenManager: _TokenManagerInternal?
  
  private var confirmRegistrationChallenge: MobileVerificationChanllenge?
  
  private func confirmBinderation() {
    guard let challenge = confirmRegistrationChallenge,
      let networkService = networkService
      else {
        delegate?.loginSession(self, failedWithError: RussellError.Common.inappropriateUsage)
        return
    }
    
    requestWorker.sendRequest(api: confirmToBinder(challenge), service: networkService) { result in
      self.headsUpDisplay?.dismiss()
      switch result {
      case .success(let auth):
        self.confirmRegistrationChallenge = nil
        self._handleLoginSucceeded(auth, .weak)
      case .failure(let error):
        self._handleLoginFailed(error)
      }
    }
  }
  
  public func invalidate() {
    requestWorker.invalidate()
    delegate = nil
  }
  
  func run(networkService: NetworkService, tokenManager: _TokenManagerInternal) -> OneKeyBinderSession {
    self.networkService = networkService
    self.tokenManager = tokenManager
    
    requestWorker.sendRequest(api: oneKeyBinderAPI(), service: networkService) { [weak self] result in
      
      self?.headsUpDisplay?.dismiss()
      switch result {
      case .success(let response):
        let requestDuration = Int64(Date().timeIntervalSince1970 * 1000) - (OneKeyLogin.shared.requestServerApiTime ?? 0)
        OneKeyLogin.shared.tracker?.action(actionName: "verified_token_success", pageCategory: "russell_sdk", pageName: "ali_authorization", properties: [
          "duration": requestDuration,
          "timeout_threshold": OneKeyLogin.shared.timeout,
          "type": UseType.OneKeyBinder.rawValue
        ])
        
        switch response {
        case .left(let auth):
          self?._handleLoginSucceeded(auth, (self?.isSignup ?? false) ? .strong : .oauthBoundable)
          
        case .right(let challenge):
          self?.confirmRegistrationChallenge = challenge
          DispatchQueue.main.async {
            self?.popConfirmBinder(challenge)
          }
        }
        
      case .failure(let error):
        
        OneKeyLogin.shared.tracker?.action(actionName: "verified_token_failed", pageCategory: "russell_sdk", pageName: "ali_authorization", properties: [
          "timeout_threshold": OneKeyLogin.shared.timeout,
          "verified_token_failed_reason": error.localizedDescription,
          "type": UseType.OneKeyBinder.rawValue
        ])
        guard let self = self else {
          return
        }
        DispatchQueue.main.async {
          // Handle Error
          switch error {
          case RussellError.Binding.mobileAlreadyBound,
               RussellError.RealNameVerification.pleaseUseMobileToLogin:
            self._popSignWarn(error)
            
          case RussellError.RealNameVerification.sessionExpired:
            Logger.info("one key binder session is timeout")
            self._warnSessionExpired(error)
              
          case RussellError.RealNameVerification.weekBindExceeded:
            OneKeyLogin.shared.tracker?.action(actionName: "relationship_too_much_error", properties: nil)
            self.headsUpDisplay?.showError(error.localizedDescription)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
              self.headsUpDisplay?.dismiss()
              self._handleToDefaultBinder(error)
            }
            
          default:
            self.headsUpDisplay?.showError("绑定失败，请重新绑定")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
              self.headsUpDisplay?.dismiss()
              self._handleToDefaultBinder(error)
            }
          }
        }
      }
    }
    return self
  }
  
  private func _handleToDefaultBinder(_ error: Error) {
    if let oneKeyBinderViewController = self.fromViewController as? OneKeyBinderViewController {
      OneKeyLogin.shared.tracker?.action(actionName: "binding_failed", pageCategory: "russell_sdk", pageName: "ali_authorization", properties: [
        "currentStatus": 0,
        "targetStatus": error
      ])
      oneKeyBinderViewController.binderBlock(Russell.UI.Container.presentation(self.fromViewController), self.sessionID, self.isSignup, false, .oneBindingFailed)
    }
  }
  
  private func _handleLoginSucceeded(_ auth: Authentication, _ targetStatus: TargetMobileStatusTracking) {
    OneKeyLogin.shared.tracker?.action(actionName: "binding_success", pageCategory: "russell_sdk", pageName: "ali_authorization", properties: [
      "currentStatus": 0,
      "targetStatus": targetStatus.rawValue
    ])
    tokenManager?.updateToken(auth.result.toToken())
    DispatchQueue.main.async {
      self.fromViewController.dismiss(animated: true, completion: nil)
      self.delegate?.loginSession(self, succeededWithResult: LoginResult(from: auth.result))
    }
  }
  
  private func _handleLoginFailed(_ error: Error) {
    OneKeyLogin.shared.tracker?.action(actionName: "binding_failed", pageCategory: "russell_sdk", pageName: "ali_authorization", properties: [
      "currentStatus": 0,
      "targetStatus": error
    ])
    DispatchQueue.main.async {
      self.fromViewController.dismiss(animated: true, completion: nil)
      self.delegate?.loginSession(self, failedWithError: error)
    }
  }
  
  private func _popSignWarn(_ error: Error) {
    
    OneKeyLogin.shared.tracker?.action(actionName: "getback_to_login", properties: nil)
    RealNameCertificationAlert.mobileAlreadyBound.show(
      in: self.fromViewController,
      confirmTrack: OneKeyLogin.shared.tracker?.lazyAction(name: "click_getback_to_login_existed_account", properties: nil),
      cancelTrack: OneKeyLogin.shared.tracker?.lazyAction(name: "click_getback_to_login_rebinding", properties: nil),
      cancelAction: { [weak self] in
        guard let self = self else {
          return
        }
        self._handleToDefaultBinder(error)
      },
      completion: {
        self._handleLoginFailed(error)
    })
  }
  
  private func _warnSessionExpired(_ error: Error) {
    OneKeyLogin.shared.tracker?.action(actionName: "relogin_page_stay_too_long", properties: nil)
    RealNameCertificationNotice.sessionExpired.show(htmlMessage: nil, in: self.fromViewController, confirmTrack: OneKeyLogin.shared.tracker?.lazyAction(name: "click_relogin", properties: nil)) {
      self._handleLoginFailed(error)
    }
  }
  
}

// MARK: APIConfig
extension OneKeyBinderSession {
  
  func oneKeyBinderAPI() -> API<Either<Authentication, MobileVerificationChanllenge>> {
    return API(method: .post, path: "/api/v2/respond_to_auth_challenge", body: [
      "challengeType": BinderChallengeType,
      "session": sessionID,
      "poolId": poolID,
      "oneTapParams": auth.parameters(poolID: poolID, timestampInSec: Int(Date().timeIntervalSince1970)),
      "isSignup": isSignup
    ])
  }
  
  func confirmToBinder(_ challenge: MobileVerificationChanllenge) -> API<Authentication> {
    return API(method: .post, path: "/api/v2/respond_to_auth_challenge", body: [
      "challenge_type": challenge.challengeType,
      "session": challenge.session,
      "poolId": poolID,
      "isSignup": isSignup
    ])
  }
  
}

extension OneKeyBinderSession: TwoStepOneKeyBinderSession {
  
  /// 弹出弱绑定验证框
  /// - Parameter challenge: challenge
  func popConfirmBinder(_ challenge: MobileVerificationChanllenge) {
    OneKeyLogin.shared.tracker?.action(actionName: "continue_to_verify", properties: nil)
    RealNameCertificationNotice.confirmWeakBinding.show(htmlMessage: challenge.challengeInfo?.message, in: self.fromViewController, confirmTrack: OneKeyLogin.shared.tracker?.lazyAction(name: "click_continue_to_verify_acknowledge", properties: nil)) {
      self.headsUpDisplay?.show()
      self.confirmBinderation()
    }
  }
  
}
