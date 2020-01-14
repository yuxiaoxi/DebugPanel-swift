//
//  QQLoginViewController.swift
//  RussellDemo
//
//  Created by Yunfan Cui on 2018/12/24.
//  Copyright © 2018 LLS. All rights reserved.
//

import UIKit
import Russell

final class QQLoginViewController: UIViewController {
  
  @IBOutlet private weak var label: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(close))
  }
  
  @objc private func close() {
    dismiss(animated: true, completion: nil)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  @IBAction private func login(_ sender: UIButton) {
    login()
  }
  
  private var currentSession: TwoStepRegistrationLoginSession?
  
  private func login() {
    HUD.show()
    ThirdParty.simpleAuth(forType: .qq) { (response, _) in
      guard let r = response, case let .accessToken(userID, token, _, _) = r else {
        return HUD.dismiss()
      }
      
      self.currentSession = Russell.shared?.startOAuthLoginSession(auth: QQAuth(appID: LLSShareService.qqId, accessToken: token, uID: userID), delegate: self, isSignup: true, hasUserConfirmedPrivacyInfo: true)
    }
  }
}

extension QQLoginViewController: OAuthLoginSessionDelegate {
  
  func loginSession(_ session: LoginSession, succeededWithResult result: LoginResult) {
    currentSession = nil
    HUD.dismiss()
    label.text = String(describing: result)
  }
  
  func loginSession(_ session: TwoStepRegistrationLoginSession, requiresUserToConfirmRegistrationWithExtraInfo extraInfo: [String : String]?) {
    HUD.dismiss()
    let vc = self
    let nick = extraInfo?["nick"].map { "nick = \($0) " } ?? ""
    let alertController = UIAlertController(title: "确认注册", message: "该 QQ \(nick)尚未注册账号，确认注册？", preferredStyle: .alert)
    
    let confirm = UIAlertAction(title: "注册", style: .default) { _ in
      HUD.show()
      self.currentSession?.confirmRegistration()
    }
    alertController.addAction(confirm)
    
    let cancel = UIAlertAction(title: "取消", style: .cancel) { _ in }
    alertController.addAction(cancel)
    
    vc.present(alertController, animated: true, completion: nil)
  }
  
  func loginSession(_ session: LoginSession, failedWithError error: Error) {
    currentSession = nil
    HUD.dismiss()
    label.text = error.localizedDescription
  }
  
  func sessionRequiresRealNameCertification(_ session: Session) -> Russell.UI.Container {
    HUD.dismiss()
    return .presentation(self)
  }
}
