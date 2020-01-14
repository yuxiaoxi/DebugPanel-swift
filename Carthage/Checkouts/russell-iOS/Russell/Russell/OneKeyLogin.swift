//
//  OneKeyLoginFlowWorker.swift
//  Russell
//
//  Created by zhuo yu on 2019/9/10.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit
import ATAuthSDK

let successResultCode = "600000"
/// 蜂窝网络未开启
let PNSCodeNoCellularNetwork = "600008"
let timeoutPrivacyCacheIdentify = "com.liulishuo.russell.onekeylogin.timeoutconfig"
//let ChinaUnicom = "ChinaUnicom" // 中国联通
public extension Russell {
  
  /// 阿里云一键登录，提供三步：初如始，预取号，唤起授权页登录
  enum OneKeyLoginFlow {
    
    /// 是否支持一键登录
    public static var isEnable: Bool {
      guard OneKeyLogin.shared.getNowTimeStampMillisecond() < (OneKeyLogin.shared.savePrivacyInfoTime + 5 * 60 * 1000)  else {
        OneKeyLogin.shared.privacyInfo = nil
        return false
      }
      
      return OneKeyLogin.shared.privacyInfo != nil
    }
    
    /// 运营商相关信息
    public static var privacyInfo: OneKeyPrivacyConfigModel? {
      return OneKeyLogin.shared.privacyInfo
    }
    
    /// 初始化 SDK 并获取手机掩码及运营商相关协议信息
    /// - Parameter key: 初始化密钥
    /// - Parameter phoneNumber: 手机号，可选
    /// - Parameter retriesOnceOnNetworkFailure: 网络失败时是否要重试
    /// - Parameter networkConnectionListeningTimeout: 网络失败时重试时间的 timeout
    /// - Parameter useType: 使用类型（登录 or 绑定）
    /// - Parameter completion: 回调
    public static func setAuthSDKInfo(key: String, phoneNumber: String? = "", retriesOnceOnNetworkFailure: Bool, networkConnectionListeningTimeout: TimeInterval, useType: UseType = .OneKeyLogin, completion: @escaping (_ isAccessible: Bool, _ resultDic: OneKeyPrivacyConfigModel?) -> Void = { _, _ in }) {
      OneKeyLogin.shared.setAuthSDKInfo(key: key, phoneNumber: phoneNumber, retriesOnceOnNetworkFailure: retriesOnceOnNetworkFailure, networkConnectionListeningTimeout: networkConnectionListeningTimeout, useType: useType, completion: completion)
    }
    
    /// 唤起授权页
    /// - Parameter fromViewController: 前置页
    /// - Parameter authViewController: 被弹出页
    /// - Parameter useType: 类型（登录 or 绑定）
    public static func startWakeAuthorizationViewController(useType: UseType, completion: @escaping () -> Void = {}) {
      OneKeyLogin.shared.startWakeAuthorizationViewController(useType: useType, completion: completion)
    }
    
    /// 获取 token 并发出后端请求，适合 ViewController 级定制方式来调用
    /// - Parameter appID: appID
    /// - Parameter fromViewController: 打开的授权页（一键登录）
    /// - Parameter useType: 类型
    /// - Parameter sessionID: sessionID
    /// - Parameter completion: 回调
    public static func startGetTokenAndRequest(appID: String, fromViewController: UIViewController, useType: UseType, sessionID: String, completion: @escaping (_ isSuccess: Bool, _ resultDic: [String: Any]?) -> Void = { _, _ in}) {
      OneKeyLogin.shared.startGetTokenAndLogin(appID: appID, fromViewController: fromViewController, useType: useType, sessionID: sessionID, completion: completion)
    }
    
    /// 获取 token 并发出后端请求，并调用 binder
    /// - Parameter fromViewController: fromViewController
    /// - Parameter useType: useType
    /// - Parameter sessionID: sessionID
    /// - Parameter isSignup: isSignup
    /// - Parameter delegate: delegate
    /// - Parameter completion: 回调
    public static func startGetTokenAndBinder(fromViewController: UIViewController, useType: UseType, sessionID: String, isSignup: Bool = false, delegate: PasswordLoginSessionDelegate, completion: @escaping (_ isSuccess: Bool, _ resultDic: [String: Any]?) -> Void = { _, _ in}) {
      OneKeyLogin.shared.startGetTokenAndBinder(fromViewController: fromViewController, useType: useType, sessionID: sessionID, delegate: delegate, completion: completion)
    }
  }
}

class OneKeyLogin: NSObject, HeadsUpDisplayable {
  
  var useType: UseType = .OneKeyLogin // 当前的使用类型（登录 or 绑定）
  var isEnable: Bool = true // 是否支持一键登录
  public static let shared: OneKeyLogin = OneKeyLogin()
//  private var prefetchCompletioned: Bool = false
  private var completion: ((_ isAccessible: Bool, _ resultDic: OneKeyPrivacyConfigModel?) -> Void)?
  var timeout: Int64 = -1 // ms
  private(set) var requestServerApiTime: Int64?
  var privacyInfo: OneKeyPrivacyConfigModel?
  var observer: OneKeyNetworkObserver?
  var haveRetryed: Bool = false
  var savePrivacyInfoTime: Int64 = 0
  private override init() {}
  
}

// MARK: public methods
extension OneKeyLogin {
  
  /// 初始化 SDK 并获取手机掩码及运营商相关协议信息
  /// - Parameter key: 初始化密钥
  /// - Parameter phoneNumber: 手机号，可选
  /// - Parameter retriesOnceOnNetworkFailure: 网络失败时是否要重试
  /// - Parameter networkConnectionListeningTimeout: 网络失败时重试时间的 timeout
  /// - Parameter completion: 回调
  func setAuthSDKInfo(key: String, phoneNumber: String?, retriesOnceOnNetworkFailure: Bool, networkConnectionListeningTimeout: TimeInterval, useType: UseType, completion: @escaping (_ isAccessible: Bool, _ resultDic: OneKeyPrivacyConfigModel?) -> Void = { _, _ in}) {
    self.completion = completion
    self.useType = useType // 更新 useType，留给打点使用
    TXCommonHandler.sharedInstance().setAuthSDKInfo(key) { (result) in
      let setupCode = result["resultCode"] as? String
      if setupCode == successResultCode { // Setup 成功
        
        self.asynchronouslyGetAuthorizationStatus(phoneNumber: phoneNumber, retriesOnceOnNetworkFailure: retriesOnceOnNetworkFailure, networkConnectionListeningTimeout: networkConnectionListeningTimeout)
      } else { // Setup 失败
        Logger.info("Onekey login setAuthSDKInfo: \(result) ")
        self._completionOnce(false, nil)
      }
    }
    
  }
  
  func asynchronouslyGetAuthorizationStatus(phoneNumber: String?, retriesOnceOnNetworkFailure: Bool, networkConnectionListeningTimeout: TimeInterval) {
    
    observer = OneKeyNetworkObserver(
      timeout: networkConnectionListeningTimeout,
      task: { self._syncGetAuthorization(phoneNumber: phoneNumber) },
      completion: { result in
        guard result else {
          return self._completionOnce(result, nil)
        }
        self._requestMaskPhone()
    })
    
    self.observer?.tryTask(retriesIfConnected: retriesOnceOnNetworkFailure)
  }
  
  private func _requestMaskPhone() {
    
    guard self.isEnable else {
      // 配置文件不使用一键登录功能
      return self._completionOnce(false, nil)
    }
    
    guard self.timeout < 1 else {
      return self.fetchMaskPhone(false)
    }
    
    self.fetchMaskPhone(true)
  }
  
  private func _syncGetAuthorization(phoneNumber: String?) -> Bool {
    tracker?.action(actionName: "initialize_sdk", pageCategory: "russell_sdk", pageName: "", properties: [
      "type": self.useType.rawValue
    ])
    let startTime = getNowTimeStampMillisecond()
    let result = TXCommonHandler.sharedInstance().checkEnvAvailable(phoneNumber) { (result) in
      let checkAvailableCode = result?["resultCode"].flatMap({ $0 as? String}) ?? "nil"
      if checkAvailableCode != successResultCode {
        Logger.info("Onekey login GetAuthorization faild reason: \(String(describing: result)) ")
      }
    }
    let authorizationDuration = getNowTimeStampMillisecond() - startTime // 初始化耗时统计
    Logger.info("Initialized OneKeyLoginService with result [\(result)] in [\(authorizationDuration)] msecs")
    if result {
      tracker?.action(actionName: "initialize_success", pageCategory: "russell_sdk", pageName: "", properties: [
        "duration": authorizationDuration,
         "type": self.useType.rawValue
      ])
    } else {
      tracker?.action(actionName: "initialize_failed", pageCategory: "russell_sdk", pageName: "", properties: [
        "type": self.useType.rawValue
      ])
    }
    return result
  }
  
  /// 预取号
  /// - Parameter completion: 预取号的回调
  /// - Parameter needReadTimeOutByConfig: 是否需要读取timeout配置接口
  func fetchMaskPhone(_ needReadTimeOutByConfig: Bool) {
    
    let startTime = getNowTimeStampMillisecond()
    let maskTimeout = 3.0
    if needReadTimeOutByConfig {
      Russell.shared?.downLoadConfigJson { [weak self] result in
        guard let self = self else {
          return
        }
        let nowTimeStamp = self.getNowTimeStampMillisecond()
        let fetchTimeoutDuration = nowTimeStamp - startTime // timout 配置接口耗时统计
        switch result {
        case .success(let response):
          self.tracker?.action(actionName: "consume_backend_service", pageCategory: "russell_sdk", pageName: "", properties: [
            "duration": fetchTimeoutDuration,
            "state": 0
          ])
          self.isEnable = response.result.enable
          self.timeout = response.result.timeoutMs
          if response.result.timeoutMs < fetchTimeoutDuration {
            self._completionOnce(false, nil)
          }
          let remainStamp = Double.init(self.timeout - fetchTimeoutDuration)/1000.0
          DispatchQueue.main.asyncAfter(deadline: .now() + remainStamp) {
            self._completionOnce(false, nil)
          }

        case .failure(let error):
          self.timeout = -1
          self.tracker?.action(actionName: "consume_backend_service", pageCategory: "russell_sdk", pageName: "", properties: [
            "duration": fetchTimeoutDuration,
            "state": 1
          ])
          Logger.info(error.localizedDescription)
        }
      }
    }
    tracker?.action(actionName: "pre_login", pageCategory: "russell_sdk", pageName: "", properties: [
      "type": self.useType.rawValue
    ])
    
    Logger.info("Will start fetching one key login phonemask number，运营商是：【\(String(describing: TXCommonUtils.getCurrentMobileNetworkName()))】")
    DispatchQueue(label: "com.liulishuo.russell.onekey-fetchmaskphone", qos: .userInitiated).async {
      TXCommonHandler.sharedInstance().getMaskPhone(withTimeout: TimeInterval(maskTimeout)) { [weak self] (result) in
        guard let self = self else {
          return
        }
        
        let preFetchCode = result["resultCode"].flatMap({ $0 as? String}) ?? "nil"
        let nowTimeStamp = self.getNowTimeStampMillisecond()
        let preFetchDuration = nowTimeStamp - startTime // 预取号耗时统计
        
        let status: Bool
        if preFetchCode == successResultCode {
          Logger.info("Successfully got one key login maskphone number")
          self.tracker?.action(actionName: "pre_login_success", pageCategory: "russell_sdk", pageName: "", properties: [
            "duration": preFetchDuration,
            "type": self.useType.rawValue
          ])
          let privacyName = result["privacyName"].flatMap({ $0 as? String}) ?? ""
          let phoneMaskNumber = result["number"].flatMap({ $0 as? String}) ?? ""
          let privacyUrl = result["privacyUrl"].flatMap({ $0 as? String}) ?? ""
          let operatorId = result["operatorId"] as? Int64
          self.privacyInfo = OneKeyPrivacyConfigModel(number: phoneMaskNumber, resultCode: preFetchCode, privacyName: privacyName, operatorId: operatorId ?? 1, privacyUrl: privacyUrl)
          self.savePrivacyInfoTime = nowTimeStamp
          status = true
        } else {
          Logger.info("Failed to get one key login phone number: result code [\(preFetchCode)], error message [\(result)]，preFetchDuration [\(preFetchDuration)]")
          self.tracker?.action(actionName: "pre_login_failed", pageCategory: "russell_sdk", pageName: "", properties: [
            "pre_login_failed_reason": preFetchCode,
            "duration": preFetchDuration,
            "type": self.useType.rawValue
          ])
          status = false
        }
        
        guard preFetchCode != PNSCodeNoCellularNetwork else {
          // 没有蜂窝网络
          guard self.haveRetryed else {
            // 是否被重试
            self.haveRetryed = true
            return self.observer!.startNetworkListenning()
          }
          return self._completionOnce(status, self.privacyInfo)
        }

        return self._completionOnce(status, self.privacyInfo)
      }
    }
  }
  
  /// 唤起授权页
  /// - Parameter fromViewController: 前置页
  /// - Parameter authViewController: 被弹出页
  /// - Parameter useType: 类型（登录 or 绑定）
  func startWakeAuthorizationViewController(useType: UseType, completion: @escaping () -> Void = {}) {
    
    self.tracker?.enter(page: "ali_authorization", properties: [
      "duration": 0,
      "timeout_threshold": self.timeout,
      "type": useType.rawValue
    ])
    completion()
  }
  
  /// 获取 Token 和请求
  /// - Parameter appID: appID
  /// - Parameter fromViewController: fromViewController
  /// - Parameter useType: useType
  /// - Parameter sessionID: sessionID
  /// - Parameter completion: completion
  func startGetTokenAndLogin(appID: String, fromViewController: UIViewController, useType: UseType, sessionID: String, completion: @escaping (_ isSuccess: Bool, _ resultDic: [String: Any]?) -> Void = { _, _ in}) {
    getLoginTokenBySDK(fromViewController: fromViewController, useType: useType, block: { (token) in
      self.login(appID: appID, accessToken: token, completion: completion)
    }, completion: completion)
  }
  
  func startGetTokenAndBinder(fromViewController: UIViewController, useType: UseType, sessionID: String, isSignup: Bool = false, delegate: PasswordLoginSessionDelegate, completion: @escaping (_ isSuccess: Bool, _ resultDic: [String: Any]?) -> Void = { _, _ in}) {
    getLoginTokenBySDK(fromViewController: fromViewController, useType: useType, block: { (token) in
      self.oneKeyBinder(sessionID: sessionID, accessToken: token, isSignup: isSignup, delegate: delegate, fromViewController: fromViewController)
    }, completion: completion)
  }
  
  func getLoginTokenBySDK(fromViewController: UIViewController, useType: UseType, block: @escaping (_ accessToken: String) -> Void = { _ in}, completion: @escaping (_ isSuccess: Bool, _ resultDic: [String: Any]?) -> Void = { _, _ in}) {
    let startTime = self.getNowTimeStampMillisecond()
    //获取一键登录token
    Logger.info("Start getting one key login token")
    TXCommonHandler.sharedInstance().getLoginToken(withTimeout: TimeInterval(3.0), controller: fromViewController) { [weak self] (result) in
      let code = result["resultCode"].flatMap({ $0 as? String}) ?? "nil"
      let msg = result["msg"] as? String
      Logger.info("Got one key login token result: code [\(code)], message [\(msg ?? "nil")]")
      if code == successResultCode {
        let token = result["token"] as? String
        //获取token成功，请求业务服务端API，获取手机号码
        let tokenSuccessDuration = (self?.getNowTimeStampMillisecond() ?? 0) - startTime
        self?.tracker?.action(actionName: "return_token_success", pageCategory: "russell_sdk", pageName: "ali_authorization", properties: [
          "duration": tokenSuccessDuration,
          "timeout_threshold": self?.timeout ?? 3000,
          "type": useType.rawValue
        ])
        if useType == .OneKeyBinder { // 一键绑定的时候需要关掉当前等待视图
          DispatchQueue.main.async {
            completion(true, nil)
          }
        }
        block(token ?? "")
        
      } else {
        var response = [String: Any]()
        response["type"] = OneKeyLoginBackType.getTokenFailed
        response["data"] = result
        self?.tracker?.action(actionName: "return_token_failed", pageCategory: "russell_sdk", pageName: "ali_authorization", properties: [
          "return_token_failed_reason": code,
          "timeout_threshold": self?.timeout ?? 3000,
          "type": useType.rawValue
        ])
        if useType == .OneKeyLogin {
          DispatchQueue.main.async {
            self?.headsUpDisplay?.showError("一键登录失败")
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self?.headsUpDisplay?.dismiss()
            completion(false, response)
          }
        } else {
          DispatchQueue.main.async {
            completion(false, response)
          }
        }
      }
    }
  }
  
  /// 执行一次回调
  /// - Parameter isSuccess: 是否成功
  /// - Parameter resultDic: 数据
  private func _completionOnce(_ isSuccess: Bool, _ resultDic: OneKeyPrivacyConfigModel?) {
    guard let completion = self.completion else { return }
    self.completion = nil
    DispatchQueue.main.async {
      completion(isSuccess, resultDic)
    }
  }
}

// MARK: _Trackable protocol
extension OneKeyLogin {
  
  var tracker: DataTracker? {
    return Russell.shared?.dataTracker
  }
}

// MARK: private methods
extension OneKeyLogin {
  
  func login(appID: String, accessToken: String, completion: @escaping (_ isSuccess: Bool, _ resultDic: [String: Any]?) -> Void) {
    self.requestServerApiTime = getNowTimeStampMillisecond()
    _ = Russell.shared?.startOneKeyLoginByPhoneSession(auth: OneKeyLoginOAuth(appID: appID, accessToken: accessToken), isSignup: false, completion: completion)
  }
  
  func oneKeyBinder(sessionID: String, accessToken: String, isSignup: Bool, delegate: OneKeyBinderSessionDelegate, fromViewController: UIViewController) {
    self.requestServerApiTime = getNowTimeStampMillisecond()
    _ = Russell.shared?.startOneKeyBinderByPhoneSession(auth: OneKeyBinderOAuth(accessToken: accessToken), sessionID: sessionID, isSignup: isSignup, delegate: delegate, fromViewController: fromViewController)
  }
  
  func getNowTimeStampMillisecond() -> Int64 {
    let dateNow = Date()//当前时间
    let timeStamp = Int64(dateNow.timeIntervalSince1970 * 1000)
    return timeStamp
  }
}

/// timeout 配置的模型
struct TimeoutConfig: Decodable {
  
  struct Result: Decodable {
    let timeoutMs: Int64
    let enable: Bool
  }
  
  let result: Result
  enum CodingKeys: String, CodingKey {
    case result = "aliyunOneTap"
  }
}
