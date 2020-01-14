//
//  BindEmailFlowWorker.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/2/19.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

struct SetPasswordDialog: Decodable {
  let id: String
  
  enum CodingKeys: String, CodingKey {
    case id = "session"
  }
}

final class BindEmailFlowWorker: VerificationCodeFlowWorker<SetPasswordDialog> {
  
  override var authFlow: String {
    return "BIND_EMAIL"
  }
  
  override var kind: Kind {
    return .email
  }
  
  override func verifyCodeAPI(account: String, code: String, sessionID: String) -> API<VerificationResponse> {
    let params: [String: Any] = [
      "poolId": poolID,
      "email": account,
      "code": code,
      "session": sessionID
    ]
    
    return API(method: .post, path: "/api/v2/bind_email", body: params)
  }
  
  override var uniqueErrorMappings: [RussellError.ErrorMapping] {
    return [RussellError.emailSessionErrorMapping, RussellError.setPasswordErrorMapping]
  }
}
