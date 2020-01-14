//
//  EmailLoginSessionFlowWorker.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/3/25.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

final class EmailRegisterSessionFlowWorker: VerificationCodeFlowWorker<SetPasswordOrConfirmToRegisterChallenge> {
  
  override var authFlow: String {
    return "LOGIN_BY_CODE"
  }
  
  override var kind: Kind {
    return .email
  }
  
  override func verifyCodeAPI(account: String, code: String, sessionID: String) -> API<VerificationResponse> {
    let params: [String: Any] = [
      "challengeType": "VERIFY_CODE",
      "codeResp": [
        "uid": account,
        "code": code
      ],
      "poolId": poolID,
      "session": sessionID
    ]
    
    return API(method: .post, path: "/api/v2/respond_to_auth_challenge", body: params)
  }
  
  override var uniqueErrorMappings: [RussellError.ErrorMapping] {
    return [RussellError.emailSessionErrorMapping, RussellError.loginSessionErrorMapping, RussellError.setPasswordErrorMapping]
  }
}

typealias SetPasswordOrConfirmToRegisterChallenge = Either<SetPasswordChallenge, ConfirmToRegisterChallenge>
