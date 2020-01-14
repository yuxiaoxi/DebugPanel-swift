//
//  BindWechatViewController.swift
//  RussellDemo
//
//  Created by Yunfan Cui on 2019/2/22.
//  Copyright © 2019 LLS. All rights reserved.
//

import Loki
import Russell
import UIKit

final class BindWechatViewController: UIViewController {
  
  private var session: BindOAuthSession<WechatAuth>?
  
  @IBAction private func bind(_ sender: AnyObject?) {
    
    ThirdParty.simpleAuth(forType: .wechat) { response, _ in
      guard let r = response, case .code(let code) = r else {
        return HUD.dismiss()
      }
      self.session = Russell.shared?.startBindOAuthSession(auth: WechatAuth(appID: LLSShareService.wechatId, code: code), delegate: self)
    }
  }
}

extension BindWechatViewController: BindSessionDelegate {
  
  func sessionSucceeded(_ session: BindSession) {
    HUD.showSuccess(withStatus: "Done")
  }
  
  func session(_ session: BindSession, failedWithError error: Error) {
    HUD.showError(withStatus: error.localizedDescription)
  }
}
