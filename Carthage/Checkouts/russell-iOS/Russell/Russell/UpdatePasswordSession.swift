//
//  UpdatePasswordSession.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/7/4.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

struct PasswordUpdateRequest {
  let old: String?
  let new: String
}

public protocol UpdatePasswordSessionDelegate: class {
  /// 更新密码成功
  func sessionSucceeded(_ session: Session)
  
  /// 更新密码出错。详见[文档](https://git.llsapp.com/common/protos/tree/master/liulishuo/backend/russell/v2#重置密码)
  func session(_ session: Session, failedWithError error: Error)
}

final class UpdatePasswordSession: Session {
  private let request: PasswordUpdateRequest
  private let poolID: String
  private weak var delegate: UpdatePasswordSessionDelegate?
  init(request: PasswordUpdateRequest, poolID: String, delegate: UpdatePasswordSessionDelegate) {
    self.request = request
    self.poolID = poolID
    self.delegate = delegate
  }
  
  private let requestWorker = SingleRequestWorker(extraErrorMappings: [RussellError.updatePasswordErrorMapping])
  var tokenRetriever = { Russell.currentAccessToken }
  
  func run(service: NetworkService) {
    do {
      try validatePassword(request.new)
      requestWorker.sendRequest(api: updatePasswordAPI(), service: service) { (result) in
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
    } catch {
      DispatchQueue.main.async {
        self.delegate?.session(self, failedWithError: error)
      }
      
    }
  }
  
  var flow: Flow { return .resetPassword }
  func invalidate() {
    requestWorker.invalidate()
  }
  
  @inline(__always)
  private func validatePassword(_ password: String) throws {
    if password.count < 6 {
      throw RussellError.UpdatePassword.passwordTooShort
    }
  }
  
  @inline(__always)
  private func updatePasswordAPI() -> API<Empty> {
    var body: [String: Any] = [
      "token": tokenRetriever() ?? "",
      "password": request.new,
      "poolId": poolID
    ]
    if let old = request.old, !old.isEmpty {
      body["currentPwd"] = old
    }
    return API(method: .post,
               path: "/api/v2/set_password",
               body: body)
  }
}
