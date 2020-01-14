//
//  LogoutSession.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/2/19.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

final class LogoutSession: Session {
  
  var flow: Flow { return .logout }
  
  func invalidate() {}
  
  private let worker = SingleRequestWorker(extraErrorMappings: [])
  
  func logout(networkService: NetworkService, tokenManager: _TokenManagerInternal) {
    guard let token = tokenManager.tokenStorage.token else { return }
    
    tokenManager.invalidateToken()
    let api = logoutAPI(with: token)
    worker.sendRequest(api: api, service: networkService, completion: { _ in })
  }
  
  @inline(__always)
  private func logoutAPI(with token: Token) -> API<Void> {
    return API(method: .post, path: "/api/v2/sign_out", body: ["token": token.accessToken, "refreshToken": token.refreshToken])
  }
}
