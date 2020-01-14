//
//  ResetPasswordFlowWorker.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/2/20.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

struct SetPasswordChallenge: Decodable {
  
  let sessionID: String
  
  enum CodingKeys: String, CodingKey {
    case session
    case challengeType
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let challengeType = try container.decode(String.self, forKey: .challengeType)
    guard challengeType == "SET_PASSWORD" else {
      throw DecodingError.dataCorruptedError(forKey: .challengeType, in: container, debugDescription: "Unmatched challenge type: \(challengeType)")
    }
    sessionID = try container.decode(String.self, forKey: .session)
  }
}

final class ResetPasswordFlowWorker: VerificationCodeFlowWorker<SetPasswordChallenge> {
  
  private let _kind: Kind
  
  required init(kind: Kind, poolID: String, networkService: NetworkService) {
    
    switch kind {
    case .email: _kind = .email
    case .sms, .smsResetPassword, .mobileVerification: _kind = .smsResetPassword
    }
    
    super.init(poolID: poolID, networkService: networkService)
  }
  
  override var kind: Kind {
    return _kind
  }
  
  override var authFlow: String {
    return "RESET_PWD"
  }
  
  override var uniqueErrorMappings: [RussellError.ErrorMapping] {
    return [RussellError.setPasswordErrorMapping]
  }
  
  override func verifyCodeAPI(account: String, code: String, sessionID: String) -> API<VerificationResponse> {
    let params: [String: Any] = [
      "challengeType": "VERIFY_CODE",
      "session": sessionID,
      "poolId": poolID,
      "codeResp": ["code": code, "uid": account]
    ]
    
    return API(method: .post, path: "/api/v2/respond_to_auth_challenge", body: params)
  }
}
