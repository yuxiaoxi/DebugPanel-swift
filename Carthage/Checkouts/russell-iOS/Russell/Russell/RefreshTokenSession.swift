//
//  RefreshTokenSession.swift
//  Russell
//
//  Created by Yunfan Cui on 2018/12/18.
//  Copyright © 2018 LLS. All rights reserved.
//

import Foundation

/// 更新 token 被定义为一个 session，于其他 session 互斥。更新 token 过程中启动其他 session 会使其失效，并在稍后回调 nil。
final class RefreshTokenSession: Session {
  
  private let networkService: NetworkService
  init(networkService: NetworkService) {
    self.networkService = networkService
  }
  
  var flow: Flow {
    return .refreshToken
  }
  
  private let requestWorker = SingleRequestWorker(extraErrorMappings: [RussellError.refreshTokenErrorMapping])
  
  func invalidate() {
    requestWorker.invalidate()
  }
  
  func refreshToken(from currentToken: Token, completion: @escaping (RussellResult<Token>) -> Void) {
    
    let api = refreshAPI(token: currentToken.accessToken, refreshToken: currentToken.refreshToken)
    requestWorker.sendRequest(api: api, service: networkService) { result in
      completion(result.map { $0.token })
    }
  }
}

private extension RefreshTokenSession {
  
  @inline(__always)
  func refreshAPI(token: String, refreshToken: String) -> API<TokenRefreshResponse> {
    return API(method: .post, path: "/api/v2/initiate_auth", body: [
      "authFlow": "REFRESH_TOKEN",
      "refreshTokenParams": [
        "token": token,
        "refreshToken": refreshToken
      ]
      ])
  }
}

struct TokenRefreshResponse: Decodable {
  
  let token: Token
  
  enum CodingKeys: String, CodingKey {
    case token = "authenticationResult"
  }
}
