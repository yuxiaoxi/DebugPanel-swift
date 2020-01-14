//
//  BindOAuthSession.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/1/2.
//  Copyright © 2019 LLS. All rights reserved.
//

/// 绑定第三方账号 Session
public final class BindOAuthSession<OAuthType: OAuth>: BindSession {
  
  private let auth: OAuthType
  private let poolID: String
  private weak var delegate: BindSessionDelegate?
  init(auth: OAuthType, poolID: String, delegate: BindSessionDelegate) {
    self.auth = auth
    self.poolID = poolID
    self.delegate = delegate
  }
  
  private let requestWorker = SingleRequestWorker(extraErrorMappings: [RussellError.bindingSessionErrorMapping])
  
  public func invalidate() {
    requestWorker.invalidate()
  }
  
  @discardableResult func run(networkService: NetworkService, token: String?) -> BindOAuthSession<OAuthType> {
    
    guard let token = token else {
      DispatchQueue.main.async {
        self.delegate?.session(self, failedWithError: RussellError.Binding.notLoggedIn)
      }
      return self
    }
    
    requestWorker.sendRequest(api: bindAPI(token: token), service: networkService) { result in
      
      switch result {
      case .success:
        DispatchQueue.main.async {
          self.delegate?.sessionSucceeded(self)
        }
      case .failure(let error):
        DispatchQueue.main.async {
          self.delegate?.session(self, failedWithError: error)
        }
      }
    }
    
    return self
  }
}

private extension BindOAuthSession {
  
  func bindAPI(token: String) -> API<Void> {
    return API(method: .post, path: "/api/v2/bind_account", body: [
      auth.parameterKey: auth.parameters(poolID: poolID, timestampInSec: Int(Date().timeIntervalSince1970)),
      "token": token
      ])
  }
}
