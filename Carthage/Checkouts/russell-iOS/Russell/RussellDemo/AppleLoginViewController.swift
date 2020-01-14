//
//  AppleLoginViewController.swift
//  RussellDemo
//
//  Created by zhuo yu on 2019/8/19.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit
import Russell
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

let loginSessionStr = "RussellDemologinSessionStr"
let bundleID = "com.liulishuo.engzo2"

final class AppleLoginViewController: UIViewController {
  @IBOutlet weak var loginProviderStackView: UIView!
  @IBOutlet weak var showLabel: UILabel!
  @IBOutlet weak var statusLabel: UILabel!
  @IBOutlet weak var responseLabel: UILabel!
  @IBOutlet weak var signOutButton: UIButton!
  private var authorizationButton: UIControl?
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(close))
    guard !UserDefaults.standard.bool(forKey: LLSShareService.appleLogined) else {
      return
    }
    if #available(iOS 13.0, *) {
      setupProviderLoginView()
    }
  }
  
  @objc private func close() {
    dismiss(animated: true, completion: nil)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    showLabel.numberOfLines = 0
    responseLabel.numberOfLines = 0
    showLabel.text = KeychainItem.currentUserIdentifier(bundleID)
    signOutButton.addTarget(self, action: #selector(loginOut), for: .touchUpInside)
    
    //判断是否已经授权登录过了
    guard !UserDefaults.standard.bool(forKey: LLSShareService.appleLogined) else {
      //已经授权登录后直接进入登录状态
      statusLabel.text = "登录成功！"
      statusLabel.sizeToFit()
      responseLabel.text = UserDefaults.standard.string(forKey: loginSessionStr)
      responseLabel.sizeToFit()
      return
    }
    if #available(iOS 13.0, *) {
      performExistingAccountSetupFlows()
    }
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    authorizationButton?.frame.origin.y = showLabel.frame.origin.y + showLabel.frame.size.height + 40
  }
  
  /// 添加appleID登录按钮
  @available(iOS 13.0, *)
  func setupProviderLoginView() {
    authorizationButton = ASAuthorizationAppleIDButton()
    authorizationButton!.addTarget(self, action: #selector(handleAuthorizationAppleIDButtonPress), for: .touchUpInside)
    authorizationButton!.frame.origin.y = showLabel.frame.origin.y + 40
    authorizationButton!.center = CGPoint(x:showLabel.center.x , y:showLabel.center.y + showLabel.frame.size.height + 40)
    self.loginProviderStackView.addSubview(authorizationButton!)
  }
  
  /// 查看用户是否已存在appleID 认证
  @available(iOS 13.0, *)
  func performExistingAccountSetupFlows() {
    let requests = [ASAuthorizationAppleIDProvider().createRequest()]
    // Create an authorization controller with the given requests.
    let authorizationController = ASAuthorizationController(authorizationRequests: requests)
    authorizationController.delegate = self
    authorizationController.presentationContextProvider = self
    authorizationController.performRequests()
    
  }
  
  ///sign in with apple 按钮点击事件
  @available(iOS 13.0, *)
  @objc func handleAuthorizationAppleIDButtonPress() {
    let appleIDProvider = ASAuthorizationAppleIDProvider()
    let request = appleIDProvider.createRequest()
    request.requestedScopes = [.fullName, .email]
    
    let authorizationController = ASAuthorizationController(authorizationRequests: [request])
    authorizationController.delegate = self
    authorizationController.presentationContextProvider = self
    authorizationController.performRequests()
  }
  
  private var currentSession: TwoStepRegistrationLoginSession?
  
  private func login(authorCode: String, appleUserInfo: AppleUserInfo) {
    statusLabel.text = "登录中..."
    statusLabel.sizeToFit()
    HUD.show()
    self.currentSession = Russell.shared?.startOAuthLoginSession(auth: AppleAuth(appID: bundleID, code: authorCode, appleUserInfo: appleUserInfo), delegate: self, isSignup: true, hasUserConfirmedPrivacyInfo: true)
  }
  
  //sign out
  @objc private func loginOut() {
    //登录标识设置为false
    UserDefaults.standard.set(false, forKey: LLSShareService.appleLogined)
    //clear loginsession
    UserDefaults.standard.set("", forKey: loginSessionStr)
    //clear userCode in keychain
    KeychainItem.deleteUserIdentifierFromKeychain(bundleID)
    close()
  }
}

@available(iOS 13.0, *)
extension AppleLoginViewController: ASAuthorizationControllerDelegate {
  
  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
      //拿到授权身份后获取关键信息
      //user 是 appleID 的唯一标识，用于本地保存
      let userCode = appleIDCredential.user
      //用户名，包括姓氏和名
      let fullName = appleIDCredential.fullName
      //appleID 的 email
      let email = appleIDCredential.email
      //用户授权码，用于我们自己服务端校验的
      let authorCode = String(data: appleIDCredential.authorizationCode!, encoding: String.Encoding.utf8) ?? ""
      
      // 将 userCode 保存在 keychain 中，用于二次授权观察
      do {
        try KeychainItem(service: bundleID, account: "userIdentifier").saveItem(userCode)
      } catch {
        print("Unable to save userIdentifier to keychain.")
      }
      // 开始 app 自己服务端注册操作
      let appUserInfo = AppleUserInfo(firstName: fullName?.familyName ?? "", lastName: fullName?.givenName ?? "", email: email ?? "")
      login(authorCode: authorCode, appleUserInfo: appUserInfo)
      
    } else if let passwordCredential = authorization.credential as? ASPasswordCredential {
      // Sign in using an existing iCloud Keychain credential.
      let username = passwordCredential.user
      let password = passwordCredential.password
      // For the purpose of this demo app, show the password credential as an alert.
    }
  }
  
  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    // 处理错误结果
    // 可以弹出错误告知用户，让用户进行再次登录授权
  }
}

@available(iOS 13.0, *)
extension AppleLoginViewController: ASAuthorizationControllerPresentationContextProviding {
  
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    return self.view.window!
  }
}

extension AppleLoginViewController: OAuthLoginSessionDelegate {
  
  func loginSession(_ session: LoginSession, succeededWithResult result: LoginResult) {
    currentSession = nil
    HUD.dismiss()
    statusLabel.text = "登录成功！"
    statusLabel.sizeToFit()
    ///存储用户信息
    
    responseLabel.text = "userId:\(String(describing: result.userID))\naccessToken:\(String(describing: result.accessToken))"
    responseLabel.sizeToFit()
    UserDefaults.standard.set(responseLabel.text, forKey: loginSessionStr)
  }
  
  func loginSession(_ session: LoginSession, failedWithError error: Error) {
    currentSession = nil
    HUD.dismiss()
    statusLabel.text = "登录失败！"
    statusLabel.sizeToFit()
  }
  
  func sessionRequiresRealNameCertification(_ session: Session) -> Russell.UI.Container {
    return .presentation(self)
  }
}
