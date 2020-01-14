//
//  RealNameInfo.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/7/25.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

public struct RealNameInfo: Decodable {
  /// 是否有效
  public let isVerified: Bool
  /// 是否需要更新（接近过期时间或者已过期）
  public let needRenew: Bool
  /// 已绑定手机号
  public let mobile: String?
  /// 是否弱绑定 (Russell SDK 内部打点使用)
  public let isWeakBinding: Bool?
  /// 对应 UI 需要展示的文案
  public let message: String?
  /// 弱绑定过期以后，更新手机号所需要的 VERIFY_MOBILE Challenge Session ID
  let session: String?
}

extension RealNameInfo {
  var hasMobile: Bool {
    return mobile?.isEmpty == false
  }
  
  var requiresToken: Bool {
    return true
  }
}

extension Russell {
  
  public func fetchRealNameInfo(checksExpirationDate: Bool = true, completion: @escaping (Result<RealNameInfo, Error>) -> Void) {
    guard let token = Russell.currentAccessToken else {
      return completion(.failure(RussellError.UserInfo.notLoggedIn))
    }
    
    networkService.request(
      api: _fetchRealNameInfoAPI(token: token, checksExpirationDate: checksExpirationDate),
      extraErrorMapping: [],
      decoder: { try JSONDecoder().decode(RealNameInfo.self, from: $0) },
      completion: { result in DispatchQueue.main.async { completion(result) } })
  }
  
  private func _fetchRealNameInfoAPI(token: String, checksExpirationDate: Bool) -> API<RealNameInfo> {
    let headers = [
      "Authorization": "Bearer \(token)",
      "X-Device-ID": deviceID,
      "X-S-Device-ID": deviceID
    ]
    return API(method: .get, path: "/api/v2/user/real_name?checkExp=\(checksExpirationDate)", body: nil, extraHeaders: headers)
  }
}
