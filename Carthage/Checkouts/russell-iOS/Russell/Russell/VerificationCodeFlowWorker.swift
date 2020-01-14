//
//  VerificationCodeFlowWorker.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/1/2.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

extension VerificationCodeFlowWorker {

  struct Callback {
    var success: ((Result) -> Void)?
    var failed: ((Error) -> Void)?
    
    var requiresVerificationCode: ((_ account: String, _ info: MobileVerificationInfo?, _ timeout: Int) -> Void)?
  }
  
  enum Kind {
    case sms // SMS Verification for Login and Bind Mobile
    case email
    case smsResetPassword // SMS Verification for Resetting Password
    case mobileVerification(sessionID: String)
  }
}

class VerificationCodeFlowWorker<Result: Decodable> {
  
  let poolID: String
  private let networkService: NetworkService
  
  init(poolID: String, networkService: NetworkService) {
    self.poolID = poolID
    self.networkService = networkService
  }
  
  // MARK: - Overrides
  
  /// Override to determine subclass auth flow
  var authFlow: String {
    fatalError("Subclass MUST override this")
  }
  
  /// Override to determine verification kind
  var kind: Kind {
    fatalError("Subclass MUST override this")
  }
  
  /// Override to specify unique error mapping functions for current flow
  var uniqueErrorMappings: [RussellError.ErrorMapping] {
    return []
  }
  
  /// Override to implement last step request handling
  func verifyCodeAPI(account: String, code: String, sessionID: String) -> API<VerificationResponse> {
    fatalError("Subclass MUST override this")
  }
  
  // MARK: - Internal APIs
  
  final var callbacks = Callback()
  
  final var extraParameters: [String: Any]?
  final var extraHeaders: [String: String] = [:]
  
  final var tracker: DataTracker?
  
  final func sendVerificationCode(to account: String) {
    
    defer { stateLock.signal() }
    stateLock.wait()
    
    guard state.transfer(to: .sendVerificationCode(account: account)) else {
      Monitor.trackError(.unexpectedBehavior, description: "当前状态\(state) 无法转换成 `sendVerificationCode`")
      return notifyUnmatchedState()
    }
    
    if let session = sessionCache.session(for: account),
      state.transfer(to: .verificationCodeChallenge(account: account, sessionID: session.id)) { // session cache hits
      DispatchQueue.main.async {
        self.callbacks.requiresVerificationCode?(account, session.info, session.timeout)
      }
    } else {
      requestVerificationCode(for: account)
    }
  }
  
  final func verify(code: String) {
    defer { stateLock.signal() }
    stateLock.wait()
    
    guard case State.verificationCodeChallenge(let account, let sessionID) = state else {
      Monitor.trackError(.unexpectedBehavior, description: "当前不是 `verificationCodeChallenge` 状态")
      return notifyUnmatchedState()
    }
    
    var api = verifyCodeAPI(account: account, code: code, sessionID: sessionID)
    updateAPI(&api)
    requestWorker.sendRequest(api: api, service: networkService) { [weak self] result in
      guard let self = self else { return }
      
      defer { self.stateLock.signal() }
      self.stateLock.wait()
      
      guard case State.verificationCodeChallenge(account: account, sessionID: sessionID) = self.state else {
        Monitor.trackError(.unexpectedBehavior, description: "当前不是 `verificationCodeChallenge` 状态，无法处理回调")
        return self.notifyUnmatchedState()
      }
      
      switch result {
      case .success(let response):
        self.handleResponse(response, account: account, id: sessionID)
      case.failure(let error):
        self.notify(error: error)
      }
    }
  }
  
  final func resendVerificationCode() {
    defer { stateLock.signal() }
    stateLock.wait()
    
    switch state {
    case .sendVerificationCode(let account),
         .verificationCodeChallenge(let account, _),
         .geeTestChallenge(let account, _, _),
         .success(_, let account):

      guard state.transfer(to: .sendVerificationCode(account: account)) else {
        Monitor.trackError(.unexpectedBehavior, description: "重发验证码不能在 \(state) 状态下触发")
        notifyUnmatchedState()
        break
      }
      requestVerificationCode(for: account)
      
    default:
      Monitor.trackError(.unexpectedBehavior, description: "重发验证码不能在 \(state) 状态下触发")
      notifyUnmatchedState()
    }
  }
  
  final func invalidate() {
    defer { stateLock.signal() }
    stateLock.wait()
    
    state = .invalid
    
    requestWorker.invalidate()
    captchaVerifier = nil
  }
  
  // MARK: - Atomic States
  
  enum State: Equatable {
    /// 当前无任何流程
    case idle
    /// 尝试请求验证码
    case sendVerificationCode(account: String)
    /// 等待用户输入短信验证码
    case verificationCodeChallenge(account: String, sessionID: String)
    /// GeeTest 验证码验证流程
    case geeTestChallenge(account: String, captchaID: String, param: CaptchaVerifier.Params)
    /// 验证成功
    case success(id: String, account: String)
    /// 失效
    case invalid
    
    /// 短信登录流程的状态迁移
    @discardableResult mutating func transfer(to targetState: State) -> Bool {
      let couldTransfer = self.couldTransfer(to: targetState)
      if couldTransfer {
        self = targetState
      } else {
        // log error
      }
      return couldTransfer
    }
    
    private func couldTransfer(to targetState: State) -> Bool {
      switch (self, targetState) {
        
      case (.invalid, _): // invalid state cannot transfer to any other state
        return false
        
      case (_, .invalid): // invalidate session
        return true
        
      case (_, .idle), // any state excepts .invalid can transfer to .idle
           (_, .sendVerificationCode): // any state excepts .invalid can transfer to .login
        return true
        
      case (.sendVerificationCode(let account1), .verificationCodeChallenge(let account2, _)), // send verification code -> verify code
           (.sendVerificationCode(let account1), .geeTestChallenge(let account2, _, _)), // send verification code -> verify captcha
           (.verificationCodeChallenge(let account1, _), .geeTestChallenge(let account2, _, _)), // verify verification code -> verify captcha
           (.geeTestChallenge(let account1, _, _), .verificationCodeChallenge(let account2, _)): // verify captcha -> verify verification code
        return account1 == account2
        
      case (.geeTestChallenge(_, let id1, _), .success(let id2, _)), // verify captcha -> success
           (.verificationCodeChallenge(_, let id1), .success(let id2, _)): // verify sms code -> success
        return id1 == id2
        
      default:
        return false
      }
    }
  }
  
  final var state: State = .idle
  private var stateLock = DispatchSemaphore(value: 1)
  
  // MARK: - Network Handling
  
  @inline(__always)
  private func sendVerificationCodeAPI(for account: String) -> API<Challenge> {
    switch kind {
    case .email:
      return VerificationCodeAPI.sendEmail(to: account, authFlow: authFlow, poolID: poolID, timestampInSec: Int(Date().timeIntervalSince1970), extras: extraParameters)
    case .sms:
      return VerificationCodeAPI.sendSMS(mobile: account, authFlow: authFlow, poolID: poolID, timestampInSec: Int(Date().timeIntervalSince1970), extras: extraParameters, containerKey: "smsCodeParams")
    case .smsResetPassword:
      return VerificationCodeAPI.sendSMS(mobile: account, authFlow: authFlow, poolID: poolID, timestampInSec: Int(Date().timeIntervalSince1970), extras: extraParameters, containerKey: "codeParams")
    case .mobileVerification(let sessionID):
      return VerificationCodeAPI.sendSMS(sessionID: sessionID, mobile: account, poolID: poolID, timestampInSec: Int(Date().timeIntervalSince1970))
    }
  }
  
  private func requestVerificationCode(for account: String) {
    var api = sendVerificationCodeAPI(for: account)
    updateAPI(&api)
    requestWorker.sendRequest(api: api, service: networkService) { [weak self] result in
      self?.sendVerificationCodeCallback(account: account, result: result)
    }
  }
  
  private var defaultErrorMappings: [RussellError.ErrorMapping] {
    switch kind {
    case .email:
      return [RussellError.emailSessionErrorMapping]
    case .sms, .smsResetPassword, .mobileVerification:
      return [RussellError.smsSessionErrorMapping]
    }
  }
  
  private lazy var requestWorker = SingleRequestWorker(extraErrorMappings: self.uniqueErrorMappings + self.defaultErrorMappings)
  
  private func sendVerificationCodeCallback(account: String, result: RussellResult<Challenge>) {
    defer { stateLock.signal() }
    stateLock.wait()
    
    guard case State.sendVerificationCode(account: account) = state else {
      Monitor.trackError(.unexpectedBehavior, description: "当前不是 `sendVerificationCode`，无法处理回调")
      return notifyUnmatchedState()
    }
    
    switch result {
    case .success(let response):
      handleResponse(.right(response), account: account, id: "")
    case .failure(let error):
      notify(error: error)
    }
  }
  
  private func handleResponse(_ response: VerificationResponse, account: String, id: String) {
    switch response {
      
    case .left(let result) where state.transfer(to: .success(id: id, account: account)):
      DispatchQueue.main.async {
        self.callbacks.success?(result)
      }
      
    case .right(let challenge):
      switch challenge.kind {
        
      case .verificationCode where state.transfer(to: .verificationCodeChallenge(account: account, sessionID: challenge.session)):
        sessionCache.updateSession(challenge.session, info: nil, for: account)
        DispatchQueue.main.async {
          self.callbacks.requiresVerificationCode?(account, nil, 60)
        }

      case .geeTest(let param) where state.transfer(to: .geeTestChallenge(account: account, captchaID: challenge.session, param: param)):
        DispatchQueue.main.async {
          self.startCaptchaVerification(id: challenge.session, param: param)
        }
        
      case .realNameMobile(let param) where state.transfer(to: .verificationCodeChallenge(account: account, sessionID: challenge.session)):
        sessionCache.updateSession(challenge.session, info: param, for: account)
        DispatchQueue.main.async {
          self.callbacks.requiresVerificationCode?(account, param, 60)
        }
        
      case .verificationCode, .geeTest, .realNameMobile:
        Monitor.trackError(.unexpectedBehavior, description: "Challenge \(challenge) 与当前状态 \(state) 不匹配")
        notifyUnmatchedState()
      }
      
    case .left:
      Monitor.trackError(.unexpectedBehavior, description: "登录成功回调与当前账号不匹配")
      notifyUnmatchedState()
    }
  }
  
  @inline(__always)
  private func notify(error: Error) {
    DispatchQueue.main.async {
      self.callbacks.failed?(error)
    }
  }
  
  @inline(__always)
  private func notifyUnmatchedState() {
    notify(error: RussellError.Common.inappropriateUsage)
  }
  
  // MARK: - Verification Code Session Cache
  
  private let sessionCache = VerificationCodeSessionCache()
  
  // MARK: - Verify Captcha
  
  private var captchaVerifier: CaptchaVerifier? {
    didSet {
      oldValue?.delegate = nil
      oldValue?.close()
      
      captchaVerifier?.delegate = self
    }
  }
  
  #if DEBUG
  final var captchaVerifierGenerator = { CaptchaVerifier(id: $0, params: $1) }
  #endif
  
  @inline(__always)
  private func startCaptchaVerification(id: String, param: CaptchaVerifier.Params) {
    tracker?.action(actionName: "present_geetest", properties: nil)
    #if DEBUG
    captchaVerifier = captchaVerifierGenerator(id, param)
    #else
    captchaVerifier = CaptchaVerifier(id: id, params: param)
    #endif
    captchaVerifier?.start()
  }
}

// MARK: - GT3CaptchaManagerDelegate

extension VerificationCodeFlowWorker: CaptchaVerifierDelegate {
  
  final func captchaVerificationSucceeded(_ verifier: CaptchaVerifier, result: CaptchaVerifier.Result) {
    defer { stateLock.signal() }
    stateLock.wait()
    
    guard case State.geeTestChallenge(let account, verifier.id, _) = state else {
      Monitor.trackError(.unexpectedBehavior, description: "Geetest 回调发生在非 Geetest 状态")
      return notifyUnmatchedState()
    }
    
    var api = VerificationCodeAPI.verify(captchaResult: result, account: account, captchaID: verifier.id, poolID: poolID, extras: extraParameters)
    updateAPI(&api)
    requestWorker.sendRequest(api: api, service: networkService) { result in
      
      switch result {
      case .success(let response):
        self.captchaSucceeded(verifier.id, response: response)
      case .failure(let error):
        self.captchaFailed(verifier.id, error: error)
      }
    }
  }
  
  final func captchaVerificationFailed(_ verifier: CaptchaVerifier, error: CaptchaVerifier.Error) {
    defer { stateLock.signal() }
    stateLock.wait()
    
    guard case State.geeTestChallenge = state else {
      Monitor.trackError(.unexpectedBehavior, description: "Geetest 回调发生在非 Geetest 状态")
      return notifyUnmatchedState()
    }
    
    notify(error: RussellError.LoginSession.captchaError)
  }
  
  private func captchaSucceeded(_ captchaID: String, response: Challenge) {
    defer { stateLock.signal() }
    stateLock.wait()
    
    guard case State.geeTestChallenge(let account, captchaID, _) = state else {
      Monitor.trackError(.unexpectedBehavior, description: "Geetest 回调发生在非 Geetest 状态")
      return notifyUnmatchedState()
    }
    
    tracker?.action(actionName: "click_validate_geetest_success", properties: nil)
    handleResponse(.right(response), account: account, id: captchaID)
  }
  
  private func captchaFailed(_ captchaID: String, error: Error?) {
    defer { stateLock.signal() }
    stateLock.wait()
    
    guard case State.geeTestChallenge(_, captchaID, _) = state else {
      Monitor.trackError(.unexpectedBehavior, description: "Geetest 回调发生在非 Geetest 状态")
      return notifyUnmatchedState()
    }
    
    tracker?.action(actionName: "click_validate_geetest_failed  ", properties: nil)
    notify(error: error ?? RussellError.LoginSession.captchaError)
  }
}

// MARK: - API

extension VerificationCodeFlowWorker {
  
  enum VerificationCodeAPI {
    /// 请求短信验证码
    static func sendSMS(mobile: String, authFlow: String, poolID: String, timestampInSec: Int, extras: [String: Any]?, containerKey: String) -> API<Challenge> {
      
      var params: [String: Any] = [
        "authFlow": authFlow,
        "poolId": poolID,
        containerKey: [
          "mobile": mobile,
          "timestampSec": timestampInSec,
          "sig": SignatureGenerator.signatureFrom(poolID: poolID, timestampInSec: timestampInSec, extra: mobile)
        ]
      ]
      params.merge(extras ?? [:], uniquingKeysWith: { _, new in new })
      return API<Challenge>(method: .post, path: "/api/v2/initiate_auth", body: params)
    }
    
    /// (实名认证)绑定手机号
    static func sendSMS(sessionID: String, mobile: String, poolID: String, timestampInSec: Int) -> API<Challenge> {
      let params: [String: Any] = [
        "challengeType": "VERIFY_MOBILE",
        "session": sessionID,
        "poolId": poolID,
        "mobile": mobile,
        "isSignup": true
      ]
      return API<Challenge>(method: .post, path: "/api/v2/respond_to_auth_challenge", body: params)
    }
    
    /// 请求邮箱验证码
    static func sendEmail(to email: String, authFlow: String, poolID: String, timestampInSec: Int, extras: [String: Any]?) -> API<Challenge> {
      
      var params: [String: Any] = [
        "authFlow": authFlow,
        "poolId": poolID,
        "codeParams": [
          "email": email,
          "timestampSec": timestampInSec,
          "sig": SignatureGenerator.signatureFrom(poolID: poolID, timestampInSec: timestampInSec, extra: email)
        ]
      ]
      params.merge(extras ?? [:], uniquingKeysWith: { _, new in new })
      return API<Challenge>(method: .post, path: "/api/v2/initiate_auth", body: params)
    }
    
    /// 校验 GeeTest 验证码回调结果
    static func verify(captchaResult: CaptchaVerifier.Result, account: String, captchaID: String, poolID: String, extras: [String: Any]?) -> API<Challenge> {
      
      var params: [String: Any] = [
        "challengeType": "GEETEST",
        "session": captchaID,
        "poolId": poolID,
        "geetestResp": [
          "mobile": account,
          "geetestChallenge": captchaResult.challenge,
          "geetestValidate": captchaResult.validate,
          "geetestSeccode": captchaResult.seccode
        ]
      ]
      params.merge(extras ?? [:], uniquingKeysWith: { _, new in new })
      return API<Challenge>(method: .post, path: "/api/v2/respond_to_auth_challenge", body: params)
    }
  }
}

// MARK: - Data

struct Challenge: Decodable {
  
  enum Kind: Decodable {
    case verificationCode
    case realNameMobile(param: MobileVerificationInfo)
    case geeTest(param: CaptchaVerifier.Params)
    
    enum CodingKeys: String, CodingKey {
      case challengeType
      case challengeInfo
      case challengeParams
    }
    
    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let rawKind = try container.decode(String.self, forKey: .challengeType)
      switch rawKind {
      case "SMS_CODE":
        self = .verificationCode
      case "VERIFY_CODE":
        if let info = try container.decodeIfPresent(MobileVerificationInfo.self, forKey: .challengeInfo) {
          self = .realNameMobile(param: info)
        } else {
          self = .verificationCode
        }
      case "GEETEST":
        let param = try container.decode(CaptchaVerifier.Params.self, forKey: .challengeParams)
        self = .geeTest(param: param)
      default:
        throw DecodingError.dataCorruptedError(forKey: CodingKeys.challengeType, in: container, debugDescription: "Unknown challenge type: \(rawKind)")
      }
    }
  }
  
  let kind: Kind
  let session: String
  
  enum CodingKeys: String, CodingKey {
    case session
  }
  
  init(from decoder: Decoder) throws {
    kind = try Kind(from: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    session = try container.decode(String.self, forKey: .session)
  }
}

extension VerificationCodeFlowWorker {
  
  typealias VerificationResponse = Either<Result, Challenge>
}

// MARK: - API Update

extension VerificationCodeFlowWorker {
  
  private func updateAPI<T>(_ api: inout API<T>) {
    guard let extraParameters = extraParameters else { return }
    
    if let currentHeaders = api.extraHeaders {
      api.extraHeaders = currentHeaders.merging(extraHeaders, uniquingKeysWith: { _, new in new })
    } else {
      api.extraHeaders = extraHeaders
    }
    api.body?.merge(extraParameters, uniquingKeysWith: { _, new in new })
  }
}
