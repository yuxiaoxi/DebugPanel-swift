//
//  UserInfoViewController.swift
//  RussellDemo
//
//  Created by Yunfan Cui on 2019/7/8.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit
import Russell

final class UserInfoViewController: UIViewController {
  
  @IBOutlet private weak var nickField: UITextField!
  @IBOutlet private weak var userInfoTextView: UITextView!
  
  private var userInfo: Russell.UserInfo?
  
  @IBAction private func printUserInfo(_ sender: UIButton) {
    Russell.shared?.fetchUserInfo { result in
      switch result {
      case .success(let info):
        HUD.showSuccess(withStatus: "Done")
        self.userInfo = info
        
        if let wechatNick = info.profile?.oauthAccounts?.first(where: { $0.provider == .wechat })?.nick {
          self.userInfoTextView.text = "\(info)" + "\n" + "wechat nick name is \(wechatNick)"
        } else {
          self.userInfoTextView.text = "\(info)"
        }
        
        self.nickField.text = info.user.nick
      case .failure(let error):
        HUD.showError(withStatus: error.localizedDescription)
      }
    }
  }
  
  @IBAction private func updateNick(_ sender: UIButton) {
    guard let oldInfo = userInfo else { return }
    
    var newInfo = oldInfo
    newInfo.user.nick = nickField.text
    
    Russell.shared?.updateUserInfo(original: oldInfo, updated: newInfo) { error in
      if let error = error {
        HUD.showError(withStatus: error.localizedDescription)
      } else {
        HUD.showSuccess(withStatus: "Done")
      }
    }
  }
}
