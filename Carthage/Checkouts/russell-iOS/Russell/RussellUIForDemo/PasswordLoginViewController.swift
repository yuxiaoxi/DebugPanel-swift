//
//  PasswordLoginViewController.swift
//  RussellUIForDemo
//
//  Created by Yunfan Cui on 2019/1/2.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit
import Russell

final class PasswordLoginViewController: UIViewController {
  
  @IBOutlet private weak var accountField: UITextField!
  @IBOutlet private weak var passwordField: UITextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
  }
  
  @objc private func close() {
    dismiss(animated: true, completion: nil)
  }
  
  @IBAction private func login(_ sender: UIButton) {
    guard let account = accountField.text, let password = passwordField.text else {
      return
    }
    
    HUD.show(in: self)
    _ = Russell.shared?.startPasswordLoginSession(account: account, password: password, delegate: self, isSignup: false, hasUserConfirmedPrivacyInfo: false)
  }
}

extension PasswordLoginViewController: PasswordLoginSessionDelegate {
  
  func loginSession(_ session: LoginSession, succeededWithResult result: LoginResult) {
    HUD.dismiss()
    let successVC = UIViewController()
    successVC.view.backgroundColor = UIColor.white
    successVC.title = "首页"
    let mobileLabel = UILabel()
    mobileLabel.frame = CGRect(origin: CGPoint(x: UIScreen.main.bounds.size.width/2 - 100, y: 100), size: CGSize(width: 200, height: 30))
    mobileLabel.text = result.mobile ?? "号码为空"
    successVC.view.addSubview(mobileLabel)
    self.navigationController?.pushViewController(successVC, animated: true)
  }
  
  func loginSession(_ session: LoginSession, failedWithError error: Error) {
    HUD.showError(message: error.localizedDescription, in: self)
  }
  
  func sessionRequiresRealNameCertification(_ session: Session) -> Russell.UI.Container {
    HUD.dismiss()
    return .presentation(self)
  }
}
