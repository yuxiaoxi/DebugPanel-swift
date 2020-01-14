//
//  EmailCodeLoginViewController.swift
//  RussellDemo
//
//  Created by Yunfan Cui on 2019/3/25.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit
import Russell

final class EmailCodeLoginViewController: UIViewController {
  
  @IBOutlet private weak var emailField: UITextField!
  @IBOutlet private weak var codeField: UITextField!
  @IBOutlet private weak var passwordField: UITextField!
  
  private var session: EmailRegisterSession?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(close))
  }
  
  @objc private func close() {
    dismiss(animated: true, completion: nil)
  }
  
  @IBAction private func sendEmail(_ sender: AnyObject?) {
    guard let email = emailField.text else { return }
    session = Russell.shared?.startEmailRegisterSession(email: email, delegate: self)
  }
  
  @IBAction private func verify(_ sender: AnyObject?) {
    guard let code = codeField.text else { return }
    session?.verify(code: code)
  }
  
  @IBAction private func set(_ sender: AnyObject?) {
    guard let password = passwordField.text else { return }
    session?.setPassword(password)
  }
}

extension EmailCodeLoginViewController: EmailRegisterSessionDelegate {
  
  func sessionRequiresPassword(_ session: EmailRegisterSession) {
    HUD.dismiss()
    passwordField.isEnabled = true
  }
  
  func sessionRequiresVerificationCode(_ session: CodeVerificationSession) {
    codeField.isEnabled = true
  }
  
  func loginSession(_ session: TwoStepRegistrationLoginSession, requiresUserToConfirmRegistrationWithExtraInfo extraInfo: [String : String]?) {
    HUD.dismiss()
    let vc = self
    let alertController = UIAlertController(title: "确认注册", message: "该邮箱尚未注册账号，确认注册？", preferredStyle: .alert)
    
    let confirm = UIAlertAction(title: "注册", style: .default) { _ in
      HUD.show()
      self.session?.confirmRegistration()
    }
    alertController.addAction(confirm)
    
    let cancel = UIAlertAction(title: "取消", style: .cancel) { _ in }
    alertController.addAction(cancel)
    
    vc.present(alertController, animated: true, completion: nil)
  }
  
  func loginSession(_ session: LoginSession, succeededWithResult result: LoginResult) {
    HUD.showSuccess(withStatus: "Done")
  }
  
  func loginSession(_ session: LoginSession, failedWithError error: Error) {
    HUD.showError(withStatus: error.localizedDescription)
  }
}
