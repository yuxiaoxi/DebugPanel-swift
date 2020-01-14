//
//  _MobileVerificationWorker.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/7/24.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

struct MobileVerificationChanllenge: Decodable {
  let session: String
  let challengeInfo: ChallengeInfo?
  let authenticationResult: Authentication?
  let challengeParams: [String: String]?
  let challengeType: String
  
  enum CodingKeys: String, CodingKey {
    case session
    case challengeInfo
    case challengeType
    case authenticationResult
    case challengeParams
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .challengeType)
//    guard type == "VERIFY_MOBILE" else {
//      throw DecodingError.dataCorruptedError(forKey: .challengeType, in: container, debugDescription: "Only VERIFY_MOBILE challengeType is available")
//    }
    challengeType = type
    session = try container.decode(String.self, forKey: .session)
    authenticationResult = try container.decodeIfPresent(Authentication.self, forKey: .authenticationResult)
    challengeInfo = try container.decodeIfPresent(ChallengeInfo.self, forKey: .challengeInfo)
    
    guard let paramContainer = try? container.nestedContainer(keyedBy: StringCodingKey.self, forKey: .challengeParams) else {
      challengeParams = nil
      return
    }
    challengeParams = paramContainer.allKeys.reduce(into: [:]) {
      $0[$1.stringValue] = try? paramContainer.decode(String.self, forKey: $1)
    }
  }
  
 struct ChallengeInfo: Decodable {
    let status: String
    let message: String
    /// 打点用数据
    let isNewRegister: Bool
  }
}

struct MobileVerificationInfo: Decodable {
  let status: Status
  let message: String
  let isNewRegister: Bool // 打点专用
  
  enum Status: String, Decodable {
    case bound = "BOUND"
    case free = "FREE"
    case oauthBoundable = "OAUTH_BINDABLE" // 打点专用
  }
}

final class _MobileVerificationWorker: VerificationCodeFlowWorker<Authentication> {
  private let sessionID: String
  required init(sessionID: String, poolID: String, networkService: NetworkService) {
    self.sessionID = sessionID
    super.init(poolID: poolID, networkService: networkService)
  }
  
  override var kind: VerificationCodeFlowWorker<Authentication>.Kind {
    return .mobileVerification(sessionID: sessionID)
  }
  
  override var uniqueErrorMappings: [RussellError.ErrorMapping] {
    return [RussellError.bindingSessionErrorMapping, RussellError.realNameVerificationErrorMapping]
  }
  
  override func verifyCodeAPI(account: String, code: String, sessionID: String) -> API<VerificationResponse> {
    
    let params: [String: Any] = [
      "challengeType": "VERIFY_CODE",
      "session": sessionID,
      "poolId": poolID,
      "codeResp": [
        "uid": account,
        "code": code
      ],
      "isSignup": true
    ]
    
    return API(method: .post, path: "/api/v2/respond_to_auth_challenge", body: params)
  }
}

extension Russell {
  
  func _mobileVerificationWorker(session: String) -> _MobileVerificationWorker {
    return _MobileVerificationWorker(sessionID: session, poolID: poolID, networkService: networkService)
  }
  
  func _bindMobileWorker() -> BindMobileFlowWorker {
    return BindMobileFlowWorker(poolID: poolID, networkService: networkService)
  }
}
