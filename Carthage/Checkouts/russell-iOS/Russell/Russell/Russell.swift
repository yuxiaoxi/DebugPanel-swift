//
//  Russell.swift
//  Russell
//
//  Created by Yunfan Cui on 2018/12/10.
//  Copyright © 2018 LLS. All rights reserved.
//

import Foundation

/// 中台的 token，用于配制
public struct Token: Equatable, Codable {
  /// HTTP Request Header 中用的 authorization token; Bearer
  public let accessToken: String
  /// 更新过期 token 的凭证
  public let refreshToken: String
  /// 过期时间
  public let expiringDate: Date
  
  public enum CodingKeys: String, CodingKey {
    case accessToken
    case refreshToken
    case expiringDate = "expiresAtSec"
  }
  
  enum CompatibleCodingKeys: String, CodingKey {
    case expiringDate = "expiresInSec"
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    accessToken = try container.decode(String.self, forKey: .accessToken)
    refreshToken = try container.decode(String.self, forKey: .refreshToken)
    
    if let date = try? container.russell_decodeDate(forKey: .expiringDate) {
      expiringDate = date
    } else {
      let compatibleContainer = try decoder.container(keyedBy: CompatibleCodingKeys.self)
      expiringDate = try compatibleContainer.russell_decodeDate(forKey: .expiringDate)
    }
  }
  
  public init(accessToken: String, refreshToken: String, expiringDate: Date) {
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    self.expiringDate = expiringDate
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    
    try container.encode(accessToken, forKey: .accessToken)
    try container.encode(refreshToken, forKey: .refreshToken)
    try container.encode(expiringDate.timeIntervalSince1970, forKey: .expiringDate)
  }
}

extension Token {
  /// 兼容旧版的初始化方法，用于 TokenStorage 中返回当前存储的 token。
  public init(oldToken: String) {
    self.accessToken = oldToken
    self.refreshToken = ""
    self.expiringDate = .distantFuture
  }
}

// Russell 配置
extension Russell {
  /// 请求的 URL 配置。当前只有 host 一个字段需要配置。
  public struct URLConfiguration {
    let host: URL
    let usesHTTPDNS: Bool
    
    public init(host: URL, usesHTTPDNS: Bool) {
      self.host = host
      self.usesHTTPDNS = usesHTTPDNS
    }
    
    /// Platform 默认的 dev 环境登录服务，HTTPDNS 默认关闭
    public static let defaultDev = URLConfiguration(host: URL(string: "https://dev-account.thellsapi.com")!, usesHTTPDNS: false)
    /// Platform 默认的 staging 环境登录服务，HTTPDNS 默认关闭
    public static let defaultStaging = URLConfiguration(host: URL(string: "https://stag-account.thellsapi.com")!, usesHTTPDNS: false)
    /// Platform 默认的 production 环境登录服务，HTTPDNS 默认开启
    public static let defaultProduction = URLConfiguration(host: URL(string: "https://account.llsapp.com")!, usesHTTPDNS: true)
  }
  
  public struct Configuration {
    let urlConfiguration: URLConfiguration
    let poolID: String
    let deviceID: String
    let appID: String
    let tokenStorage: TokenStorage
    let autoRefreshThreasholdBeforeExpiring: TimeInterval
    let dataTracker: DataTracker
    let privacyAction: (_ container: UINavigationController) -> Void
    
    /// Russell 服务初始化配置
    ///
    /// - Parameters:
    ///   - urlConfiguration: URL 配置
    ///   - poolID: 业务方配置的 poolID，用于指定登录策略。详见接入指南: https://wiki.liulishuo.work/pages/viewpage.action?pageId=16567624
    ///   - deviceID: 设备唯一标识符。
    ///   - appID: 业务 App 在 Russell 侧对应的 App ID，填写 proto enum 对应的*小写字符串*。详见 https://git.llsapp.com/common/protos/blob/master/liulishuo/common/enums/app_id.proto
    ///   - tokenStorage: Token 存储器。新业务可以直接使用 `KeyChainTokenStorage`，老业务需要提供自己的 `TokenStorage` 实现以兼容旧版。
    ///   - autoRefreshThreasholdBeforeExpiring: Token 过期前 x 秒内尝试自动刷新当前 token
    ///   - dataTracker: 注入打点服务
    ///   - privacyAction: 隐私协议跳转回调
    ///   - container: 隐私协议跳转触发当前的 Navigation Controller 容器
    public init(urlConfiguration: Russell.URLConfiguration, poolID: String, deviceID: String, appID: String, tokenStorage: TokenStorage, autoRefreshThreasholdBeforeExpiring: TimeInterval = 0, dataTracker: DataTracker, privacyAction: @escaping (_ container: UINavigationController) -> Void) {
      self.urlConfiguration = urlConfiguration
      self.poolID = poolID
      self.deviceID = deviceID
      self.appID = appID
      self.tokenStorage = tokenStorage
      self.autoRefreshThreasholdBeforeExpiring = autoRefreshThreasholdBeforeExpiring
      self.dataTracker = dataTracker
      self.privacyAction = privacyAction
    }
  }
}

// MARK: -

/// 登录服务入口
public final class Russell {
  
  // MARK: Singleton
  
  /// shared singleton
  public private(set) static var shared: Russell?
  
  private static let lock = DispatchSemaphore(value: 1)
  
  private static var configuration: Configuration?
  
  /// 初始化 singleton 的方法
  ///
  /// - Parameters:
  ///   - configuration: 初始化配置
  public static func setup(configuration: Configuration) {
    defer { lock.signal() }
    lock.wait()
    
    guard shared == nil else { return }
    
    shared = Russell(
      networkService: Network(configuration: configuration.urlConfiguration, deviceID: configuration.deviceID, poolID: configuration.poolID, appID: configuration.appID),
      poolID: configuration.poolID,
      deviceID: configuration.deviceID,
      tokenManager: _TokenManagerInternal(tokenStorage: configuration.tokenStorage, autoRefreshThreasholdBeforeExpiring: configuration.autoRefreshThreasholdBeforeExpiring),
      dataTracker: configuration.dataTracker,
      privacyAction: configuration.privacyAction
    )
    self.configuration = configuration
    // Prepare for one key login
    OnekeyReachability.shared.startListening()
  }
  
  // MARK: Initialize
  
  let networkService: NetworkService
  let poolID: String
  let deviceID: String
  private(set) var tokenManager: _TokenManagerInternal
  let dataTracker: DataTracker
  let privacyAction: (_ container: UINavigationController) -> Void
  init(networkService: NetworkService, poolID: String, deviceID: String, tokenManager: _TokenManagerInternal, dataTracker: DataTracker, privacyAction: @escaping (_ container: UINavigationController) -> Void) {
    self.networkService = networkService
    self.poolID = poolID
    self.deviceID = deviceID
    self.tokenManager = tokenManager
    self.dataTracker = dataTracker
    self.privacyAction = privacyAction
  }
  
  // MARK: Session
  
  /// 当前正在进行的 Session
  public private(set) var currentSession: Session? {
    didSet {
      oldValue?.invalidate()
    }
  }
}

// MARK: - Session Management

extension Russell {
  
  /// 启动一个短信验证码登录的 Session
  ///
  /// - Parameters:
  ///   - mobile: 手机号。如果包含国家码，则必须以 "+" 开头。如果没有国家码，默认为 "+86"。
  ///   - delegate: 监听登录过程的代理
  ///   - isSignup: 是否注册，在 poolID 相关配置为"手机登录不自动创建账号时生效"，参见[文档](https://wiki.liulishuo.work/pages/viewpage.action?pageId=16567624)。true 则会创建新用户。false 对未创建账号的手机号会报错。
  /// - Returns: 新创建的短信验证码登录 Session
  public func startSMSLoginSession(mobile: String, delegate: SMSLoginSessionDelegate, isSignup: Bool) -> SMSLoginSession {
    let worker = SMSLoginFlowWorker(poolID: poolID, networkService: networkService)
    let session = startSession(_SMSLoginSessionInternal(delegate: delegate, flowWorker: worker, tokenManager: tokenManager, networkService: networkService, isSignup: isSignup))
    session.login(mobile: mobile)
    return session
  }
  
  /// 启动一个第三方平台登录的 Session
  ///
  /// - Parameters:
  ///   - auth: 第三方登录鉴权。
  ///   - delegate: 监听登录过程的代理
  ///   - isSignup: 是否注册，在 poolID 相关配置为"第三方登录不自动创建账号时生效"，参见[文档](https://wiki.liulishuo.work/pages/viewpage.action?pageId=16567624)。true 则会创建新用户。false 对未创建账号的第三方账号会报错。
  ///   - hasUserConfirmedPrivacyInfo: 用户是否已经同意隐私协议 (如: 是否已经勾选隐私协议选框等)
  /// - Returns: 新创建的第三方登录 Session
  public func startOAuthLoginSession<OAuthType: OAuth>(auth: OAuthType, delegate: OAuthLoginSessionDelegate, isSignup: Bool, hasUserConfirmedPrivacyInfo: Bool) -> OAuthLoginSession<OAuthType> {
    return startSession(
      OAuthLoginSession(
        auth: auth,
        poolID: poolID,
        delegate: delegate,
        isSignup: isSignup,
        privacyInfo: PrivacyInfo(hasUserConfirmed: hasUserConfirmedPrivacyInfo, action: privacyAction)
      )
        .run(networkService: networkService, tokenManager: tokenManager)
    )
  }
  
  /// 启动一个邮箱验证码注册的 Session
  ///
  /// - Parameters:
  ///   - email: 目标邮箱地址
  ///   - delegate: 监听注册过程的代理
  /// - Returns: 新创建的邮箱验证码注册 Session
  public func startEmailRegisterSession(email: String, delegate: EmailRegisterSessionDelegate) -> EmailRegisterSession {
    let worker = EmailRegisterSessionFlowWorker(poolID: poolID, networkService: networkService)
    let session = startSession(_EmailRegisterSessionInternal(delegate: delegate, flowWorker: worker, networkService: networkService))
    session.login(email: email)
    return session
  }
  
  /// 启动一个密码登录 Session
  ///
  /// - Parameters:
  ///   - account: 账号。需要是合法的手机号码('+' + '区号' + '手机号')/邮箱/用户ID
  ///   - password: 明文密码
  ///   - delegate: 监听登录过程的代理
  ///   - isSignup: 是否注册。true 则会创建新用户。false 对未创建账号的用户名会报错。
  ///   - hasUserConfirmedPrivacyInfo: 用户是否已经同意隐私协议 (如: 是否已经勾选隐私协议选框等)
  /// - Returns: 新创建的密码登录 Session
  public func startPasswordLoginSession(account: String, password: String, delegate: PasswordLoginSessionDelegate, isSignup: Bool, hasUserConfirmedPrivacyInfo: Bool) -> PasswordLoginSession {
    return startSession(
      PasswordLoginSession(
        poolID: poolID,
        account: account,
        password: password,
        delegate: delegate,
        isSignup: isSignup,
        privacyInfo: PrivacyInfo(hasUserConfirmed: hasUserConfirmedPrivacyInfo, action: privacyAction)
      )
        .run(networkService: networkService, tokenManager: tokenManager)
    )
  }
  
  /// 启动一个绑定第三方账号的 Session
  ///
  /// - Parameters:
  ///   - auth: 第三方登录鉴权。
  ///   - delegate: 监听绑定流程的代理
  public func startBindOAuthSession<OAuthType: OAuth>(auth: OAuthType, delegate: BindSessionDelegate) -> BindOAuthSession<OAuthType> {
    return startSession(BindOAuthSession(auth: auth, poolID: poolID, delegate: delegate).run(networkService: networkService, token: Russell.currentAccessToken))
  }
  
  /// 启动一个绑定手机号的 Session
  ///
  /// - Parameters:
  ///   - mobile: 需要绑定的手机号
  ///   - delegate: 监听绑定流程的代理
  public func startBindMobileSession(mobile: String, delegate: BindMobileSessionDelegate) -> BindMobileSession {
    let session = startSession(_BindMobileSessionInternal(delegate: delegate, flowWorker: BindMobileFlowWorker(poolID: poolID, networkService: networkService)))
    session.bind(mobile: mobile)
    return session
  }
  
  /// 启动一个绑定邮箱的 Session
  ///
  /// - Parameters:
  ///   - email: 需要绑定的 Email
  ///   - delegate: 监听绑定流程的代理
  public func startBindEmailSession(email: String, delegate: BindEmailSessionDelegate) -> BindEmailSession {
    let worker = BindEmailFlowWorker(poolID: poolID, networkService: networkService)
    let session = startSession(_BindEmailSessionInternal(delegate: delegate, flowWorker: worker, networkService: networkService))
    session.sendEmail(to: email)
    return session
  }
  
  /// 启动一个通过邮箱验证码重置密码的 Session
  ///
  /// - Parameters:
  ///   - email: 需要验证的邮箱地址
  ///   - delegate: 监听流程的代理
  public func startResetPasswordSession(email: String, delegate: ResetPasswordSessionDelegate) -> ResetPasswordSession {
    let worker = ResetPasswordFlowWorker(kind: .email, poolID: poolID, networkService: networkService)
    let session = startSession(_ResetPasswordSessionInternal(delegate: delegate, flowWorker: worker, networkService: networkService, tokenManager: tokenManager))
    session.sendVerificationCode(to: email)
    return session
  }
  
  /// 启动一个通过短信验证码重置密码的 Session
  ///
  /// - Parameters:
  ///   - mobile: 需要验证的手机号
  ///   - delegate: 监听流程的代理
  public func startResetPasswordSession(mobile: String, delegate: ResetPasswordSessionDelegate) -> ResetPasswordSession {
    let worker = ResetPasswordFlowWorker(kind: .smsResetPassword, poolID: poolID, networkService: networkService)
    let session = startSession(_ResetPasswordSessionInternal(delegate: delegate, flowWorker: worker, networkService: networkService, tokenManager: tokenManager))
    session.sendVerificationCode(to: mobile)
    return session
  }
  
  /// 启动一个更新密码的 Session
  ///
  /// - Parameters:
  ///   - old: 旧密码。如果用户没有设置过，可以传 nil 或 empty string
  ///   - new: 新密码。需要 ≥ 8 位，同时包含字母和数字
  ///   - delegate: 回调代理
  @discardableResult public func startUpdatePasswordSession(old: String?, new: String, delegate: UpdatePasswordSessionDelegate) -> Session {
    let request = PasswordUpdateRequest(old: old, new: new)
    let session = startSession(UpdatePasswordSession(request: request, poolID: poolID, delegate: delegate))
    session.run(service: networkService)
    return session
  }
  
  /// 启动一个手机号码一键登录的 Session
  ///
  /// - Parameters:
  ///   - access_token: loginauthority
  ///   - delegate: 监听登录过程的代理
  /// - Returns: 手机号码一键登录 Session
  public func startOneKeyLoginByPhoneSession<OAuthType: OAuth>(auth: OAuthType, isSignup: Bool, completion: @escaping (_ isSuccess: Bool, _ resultDic: [String: Any]?) -> Void) -> OneKeyLoginSession<OAuthType> {
    return startSession(OneKeyLoginSession(auth: auth, poolID: poolID, isSignup: isSignup, completion: completion).run(networkService: networkService, tokenManager: tokenManager))
  }
  
  /// 启动一个一键绑定的 Session
  /// - Parameter auth: auth
  /// - Parameter sessionID: sessionID
  /// - Parameter isSignup: 是否注册
  /// - Parameter delegate: delegate
  /// - Parameter fromViewController: fromViewController 前置页面
  public func startOneKeyBinderByPhoneSession<OAuthType: OAuth>(auth: OAuthType, sessionID: String, isSignup: Bool, delegate: OneKeyBinderSessionDelegate, fromViewController: UIViewController) -> OneKeyBinderSession<OAuthType> {
    return startSession(OneKeyBinderSession(auth: auth, poolID: poolID, sessionID: sessionID, isSignup: isSignup, delegate: delegate, fromViewController: fromViewController).run(networkService: networkService, tokenManager: tokenManager))
  }
  
  func downLoadConfigJson(completion: @escaping (_ result: Result<TimeoutConfig, Error>) -> Void = {_ in }) {
    let requestWorker = SingleRequestWorker(extraErrorMappings: [RussellError.loginSessionErrorMapping])
    requestWorker.sendRequest(api: downLoadConfigAPI(), service: networkService) { result in
      completion(result)
    }
  }
  
  func downLoadConfigAPI() -> API<TimeoutConfig> {
    guard let urlConfiguration = Russell.configuration?.urlConfiguration else {
      return API(method: .get, path: "https://account-conf.llscdn.com/russell/development/llsapp.json", body: nil, timeoutForRequest: TimeInterval(2.0))
    }
    /// timeout cdn 配置支持环境切换
    if urlConfiguration.host == URLConfiguration.defaultProduction.host {
      return API(method: .get, path: "https://account-conf.llscdn.com/russell/production/llsapp.json", body: nil, timeoutForRequest: TimeInterval(2.0))
    } else {
      return API(method: .get, path: "https://account-conf.llscdn.com/russell/development/llsapp.json", body: nil, timeoutForRequest: TimeInterval(2.0))
    }
  }
  
  /// 停止当前的 Session
  public func stopCurrentSession() {
    currentSession = nil
  }
  
  /// 登出
  @discardableResult
  public func logout() -> Session {
    let session = startSession(LogoutSession())
    session.logout(networkService: networkService, tokenManager: tokenManager)
    return session
  }
  
  @inline(__always)
  private func startSession<T: Session>(_ newSession: T) -> T {
    
    currentSession = newSession
    return newSession
  }
}

// MARK: - TokenManager

extension Russell {
  
  /// 获取当前 TokenStorage 中的 Request Authorization Token
  public func authorizationToken() -> String? {
    return tokenManager.authorizationToken()
  }
  
  /// 删除当前存储的 Token。调用该接口会废弃当前正在执行的 Session。
  public func invalidateToken() {
    currentSession = nil
    tokenManager.invalidateToken()
  }
  
  /// 向 Russell 服务器请求刷新当前 Token。
  /// - Note: 调用该方法会隐式启动一个 RefreshTokenSession。
  /// - Note: 通常在 HTTP Status Code = 403 时尝试。
  /// - Note: 上一次更新 Token 的请求尚未返回结果时，调用该接口会将 `completion` 加入回调队列，而不会触发新的请求。
  /// - Note: completion 的错误类型可能为 RussellError.RefreshToken.notLoggedIn 或者 RussellError.Common / RussellError.Response 中的一种。
  public func refreshToken(_ completion: @escaping (Error?) -> Void) {
    tokenManager.refreshToken(session: startSession(RefreshTokenSession(networkService: networkService)), completion: completion)
  }
}

// MARK: - Internal

extension Russell {
  
  static var currentAccessToken: String? {
    return shared?.tokenManager.tokenStorage.token?.accessToken
  }
}
