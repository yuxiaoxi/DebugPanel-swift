//
//  ResetPasswordViewController.swift
//  RussellDemo
//
//  Created by Yunfan Cui on 2019/2/22.
//  Copyright © 2019 LLS. All rights reserved.
//

import Russell
import UIKit

final class ResetPasswordViewController: UIViewController {
  
  @IBOutlet private weak var emailField: UITextField!
  @IBOutlet private weak var codeField: UITextField!
  @IBOutlet private weak var passwordField: UITextField!
  
  private var session: ResetPasswordSession?
  
  @IBAction private func sendEmail(_ sender: AnyObject?) {
    guard let email = emailField.text else { return }
    session = Russell.shared?.startResetPasswordSession(email: email, delegate: self)
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

extension ResetPasswordViewController: ResetPasswordSessionDelegate {
  
  func sessionRequiresPassword(_ session: ResetPasswordSession) {
    passwordField.isEnabled = true
  }
  
  func session(_ session: ResetPasswordSession, succeededWithResult result: LoginResult) {
    HUD.showSuccess(withStatus: String(describing: result))
  }
  
  func session(_ session: ResetPasswordSession, failedWithError error: Error) {
    HUD.showError(withStatus: error.localizedDescription)
  }
  
  func sessionRequiresVerificationCode(_ session: CodeVerificationSession) {
    codeField.isEnabled = true
  }
}
