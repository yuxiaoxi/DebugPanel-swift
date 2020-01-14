//
//  BindEmailViewController.swift
//  RussellDemo
//
//  Created by Yunfan Cui on 2019/2/22.
//  Copyright © 2019 LLS. All rights reserved.
//

import Russell
import UIKit

final class BindEmailViewController: UIViewController {
  
  @IBOutlet private weak var emailField: UITextField!
  @IBOutlet private weak var codeField: UITextField!
  @IBOutlet private weak var passwordField: UITextField!
  
  private var session: BindEmailSession?
  
  @IBAction private func sendEmail(_ sender: AnyObject?) {
    guard let email = emailField.text else { return }
    session = Russell.shared?.startBindEmailSession(email: email, delegate: self)
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

extension BindEmailViewController: BindEmailSessionDelegate {
  
  func sessionRequiresPassword(_ session: BindEmailSession) {
    passwordField.isEnabled = true
  }
  
  func sessionRequiresVerificationCode(_ session: CodeVerificationSession) {
    codeField.isEnabled = true
  }
  
  func sessionSucceeded(_ session: BindSession) {
    HUD.showSuccess(withStatus: "Done")
  }
  
  func session(_ session: BindSession, failedWithError error: Error) {
    HUD.showError(withStatus: error.localizedDescription)
  } 
}
