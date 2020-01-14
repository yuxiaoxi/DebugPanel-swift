//
//  UpdatePasswordViaOldViewController.swift
//  RussellDemo
//
//  Created by Yunfan Cui on 2019/7/7.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit
import Russell

final class UpdatePasswordViaOldViewController: UIViewController {
  @IBOutlet private weak var oldField: UITextField!
  @IBOutlet private weak var newField: UITextField!
  @IBOutlet private weak var confirmNewField: UITextField!
  
  @IBAction private func update(_ sender: UIButton) {
    let old = oldField.text
    guard let new = newField.text,
      let confirm = confirmNewField.text,
      new == confirm else {
        return HUD.showError(withStatus: "未输入新密码，或两次密码输入不一致！")
    }
    
    Russell.shared?.startUpdatePasswordSession(old: old, new: new, delegate: self)
  }
}

extension UpdatePasswordViaOldViewController: UpdatePasswordSessionDelegate {
  
  func sessionSucceeded(_ session: Session) {
    HUD.showSuccess(withStatus: "Done")
  }
  
  func session(_ session: Session, failedWithError error: Error) {
    HUD.showError(withStatus: error.localizedDescription)
  }
}
