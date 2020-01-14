//
//  OneKeyLoginSession.swift
//  Russell
//
//  Created by zhuo yu on 2019/9/9.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit
import ATAuthSDK

/// 登录页回调返回的类型：
///    1、预取号失败
///    2、唤起授权页失败
///    3、请求服务端接口失败
///    4、点击切换其他登录方式
///    5、拉取授权页超时
///    6、获取token失败
///    7、登录成功
public enum OneKeyLoginBackType: Int {
  case prefetchFailed
  case wakeAuthPageFailed
  case requestAPIFailed
  case clickChangeButton
  case wakeAuthPageTimeout
  case getTokenFailed
  case loginSuccess
}

/// 一键登录Session
public final class OneKeyLoginSession<OAuthType: OAuth>: LoginSession, HeadsUpDisplayable {
  
  private let auth: OAuthType
  private let poolID: String
  private let isSignup: Bool
  private var completion: (_ isSuccess: Bool, _ resultDic: [String: Any]?) -> Void
  private var isEnable: Bool?
  
  init(auth: OAuthType, poolID: String, isSignup: Bool, completion: @escaping (_ isSuccess: Bool, _ resultDic: [String: Any]?) -> Void) {
    self.auth = auth
    self.poolID = poolID
    self.isSignup = isSignup
    self.completion = completion
  }
  
  public func invalidate() {
    requestWorker.invalidate()
  }
  
  private let requestWorker = SingleRequestWorker(extraErrorMappings: [RussellError.loginSessionErrorMapping])
  private var networkService: NetworkService?
  
  func run(networkService: NetworkService, tokenManager: _TokenManagerInternal) -> OneKeyLoginSession {
    self.networkService = networkService
    
    requestWorker.sendRequest(api: oneKeyLoginAPI(), service: networkService) { result in
      
      switch result {
      case .success(let response):
        let requestDuration = Int64(Date().timeIntervalSince1970 * 1000) - (OneKeyLogin.shared.requestServerApiTime ?? 0)
        OneKeyLogin.shared.tracker?.action(actionName: "verified_token_success", pageCategory: "russell_sdk", pageName: "ali_authorization", properties: [
          "duration": requestDuration,
          "timeout_threshold": OneKeyLogin.shared.timeout,
          "type": UseType.OneKeyLogin.rawValue
        ])
        tokenManager.updateToken(response.result.toToken())
        DispatchQueue.main.async {
          self.loginSession(self, succeededWithResult: LoginResult(from: response.result))
        }
        
      case .failure(let error):
        OneKeyLogin.shared.tracker?.action(actionName: "verified_token_failed", pageCategory: "russell_sdk", pageName: "ali_authorization", properties: [
          "timeout_threshold": OneKeyLogin.shared.timeout,
          "verified_token_failed_reason": error.localizedDescription,
          "type": UseType.OneKeyLogin.rawValue
        ])
        
        DispatchQueue.main.async {
          self.headsUpDisplay?.showError("一键登录失败")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
          self.loginSession(self, failedWithError: error)
        }
      }
    }
    return self
  }
  
}

// MARK: implement LoginSessionDelegate
extension OneKeyLoginSession: LoginSessionDelegate {
  
  public func loginSession(_ session: LoginSession, succeededWithResult result: LoginResult) {
    var response = [String: Any]()
    response["type"] = OneKeyLoginBackType.loginSuccess
    response["data"] = result
    self.completion(true, response)
  }
  
  public func loginSession(_ session: LoginSession, failedWithError error: Error) {
    var result = [String: Any]()
    result["type"] = OneKeyLoginBackType.requestAPIFailed
    result["data"] = "\(error)"
    self.completion(false, result)
  }
}

// MARK: APIConfig
extension OneKeyLoginSession {
  
  func oneKeyLoginAPI() -> API<Authentication> {
    return API(method: .post, path: "/api/v2/initiate_auth", body: [
      "authFlow": auth.kind.flow,
      "poolId": poolID,
      "oneTapLoginParams": auth.parameters(poolID: poolID, timestampInSec: Int(Date().timeIntervalSince1970)),
      "isSignup": isSignup
    ])
  }
  
}
