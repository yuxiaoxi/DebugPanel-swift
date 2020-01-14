//
//  SMSLoginCoordinator.swift
//  RussellDemo
//
//  Created by Yunfan Cui on 2018/12/18.
//  Copyright © 2018 LLS. All rights reserved.
//

import UIKit
import Russell

final class SMSLoginSessionCoordinator {
  var session: SMSLoginSession?
  
  weak var navigationController: UINavigationController?
  
  weak var enterMobileViewController: UIViewController?
  
  weak var enterSMSCodeViewController: VerifySMSCodeViewController?
  
  func sendSMSCode(to mobile: String) {
    navigationController.map { HUD.show(in: $0) }
    session = Russell.shared?.startSMSLoginSession(mobile: mobile, delegate: self, isSignup: true)
  }
  
  func verifySMSCode(_ code: String) {
    navigationController.map { HUD.show(in: $0) }
    session?.verify(code: code)
  }
  
  func resendSMS() {
    session?.resendVerificationMessage()
  }
}

extension SMSLoginSessionCoordinator: SMSLoginSessionDelegate {
  
  func sessionRequiresVerificationCode(_ session: CodeVerificationSession) {
    guard let vc = enterMobileViewController else { return }
    
    HUD.dismiss()
    let targetVC = VerifySMSCodeViewController(nibName: "VerifySMSCodeViewController", bundle: Bundle(for: VerifySMSCodeViewController.self))
    targetVC.coordinator = self
    self.enterSMSCodeViewController = targetVC
    vc.navigationController?.pushViewController(targetVC, animated: true)
  }
  
  func loginSession(_ session: LoginSession, succeededWithResult result: LoginResult) {
    navigationController.map { HUD.showSuccess(message: "Done", in: $0) }
    enterSMSCodeViewController?.resultLabel.text = String(describing: result)
    if result.isNewRegister {
      
    } else {
      
    }
  }
  
  func loginSession(_ session: LoginSession, failedWithError error: Error) {
    navigationController.map { HUD.showError(message: error.localizedDescription, in: $0) }
  }
  
  func loginSession(_ session: TwoStepRegistrationLoginSession, requiresUserToConfirmRegistrationWithExtraInfo extraInfo: [String: String]?) {
    
    HUD.dismiss()
    guard let vc = navigationController else { return }
    
    let alertController = UIAlertController(title: "确认注册", message: "该手机号尚未注册账号，确认注册？", preferredStyle: .alert)
    
    let confirm = UIAlertAction(title: "注册", style: .default) { _ in
      HUD.show(in: vc)
      self.session?.confirmRegistration()
    }
    alertController.addAction(confirm)
    
    let cancel = UIAlertAction(title: "取消", style: .cancel) { _ in }
    alertController.addAction(cancel)
    
    vc.present(alertController, animated: true, completion: nil)
  }
}
