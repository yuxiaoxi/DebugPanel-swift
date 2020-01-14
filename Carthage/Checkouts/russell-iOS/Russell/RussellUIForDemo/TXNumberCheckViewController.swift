//
//  TXNumberCheckViewController.swift
//  aliyundemo
//
//  Created by zhuo yu on 2019/8/27.
//  Copyright © 2019 zhuo yu. All rights reserved.
//

import UIKit
import Russell

let TX_SCREEN_WIDTH = UIScreen.main.bounds.size.width
let TX_SCREEN_HEIGHT = UIScreen.main.bounds.size.height
let TX_STATUS_BAR_HEIGHT = UIApplication.shared.statusBarFrame.size.height
let TX_NAV_BAR_HEIGHT: CGFloat = 44.0
let TX_STATUS_NAV_BAR_HEIGHT = TX_STATUS_BAR_HEIGHT + TX_NAV_BAR_HEIGHT

class TXNumberCheckViewController: UIViewController {
  
  @IBOutlet weak var conformButton: UIButton!
  @IBOutlet weak var loginButton: UIButton!
  @IBOutlet weak var preFetchButton: UIButton!
  @IBOutlet weak var costTimeLabel: UILabel!
  @IBOutlet weak var onekeyLoginUIButton: UIButton!
  @IBOutlet weak var onekeyBinderButton: UIButton!
  @IBOutlet weak var stactView: UIStackView!
  var testAPI: QuicksilverProvider!
  private var privacyInfo: OneKeyPrivacyConfigModel?
  private var onekeyLoginButton: UIButton?
  private var changeButton: UIButton?
  private var weiXinButton: UIButton?
  private var qqButton: UIButton?
  private var weiBoButton: UIButton?
  private var emailButton: UIButton?
  private var protocolTextView: UITextView?
  private var oneKeyLoginModel: OneKeyLoginCustomModel?
  private var topPosition: CGFloat = 0
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationItem.title = "阿里号码认证"
    self.privacyInfo = Russell.OneKeyLoginFlow.privacyInfo
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.costTimeLabel.text = Russell.OneKeyLoginFlow.isEnable ? "初始化成功" : "请您先初始化！"
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.stactView.frame.origin.y = 150
    self.stactView.frame.origin.x = UIScreen.main.bounds.size.width/2 - self.stactView.frame.width / 2
    self.costTimeLabel.frame.origin.y = self.stactView.frame.origin.y + self.stactView.frame.size.height + 20
  }
  
  @objc private func close() {
    dismiss(animated: true, completion: nil)
  }
  
  private func setupSdk(wakePage: @escaping () -> Void = {}) {
    HUD.show(in: self)
    let key = "Okj0Uid+slNGLCihLtwd3L2asaUR3plcUvCNdiielJYGoZhBtattjs2T1AQG5Wyh1YoN9gefazvwqfo0/NP494H2IE+O0KOEqGpuvE177E8n5+AVXx6Ql76fXc1KOeEyZcxznIk68vJKJeDm6u9t+vHrvNfR5LdHWEeGORxR2nIHYmwXf4GWURBe8Zg9clYiY1krrL27thnwqBHKqWsrsOfqXr2hQgyVUCFZY4OMijudQxLafV0YhuyZofj5/vwG"
    Russell.OneKeyLoginFlow.setAuthSDKInfo(key: key, phoneNumber: "", retriesOnceOnNetworkFailure: true, networkConnectionListeningTimeout: 2.0) { isAccessible, resultInfo in
      HUD.dismiss()
      // resultDic example ["resultCode": 600000, "privacyName": 中国移动认证服务条款, "number": 187****6289, "operatorId": 1, "privacyUrl": https://wap.cmpassport.com/resources/html/contract.html, "msg": success]
      print("setup content: [\(String(describing: resultInfo))]")
      self.costTimeLabel.text = isAccessible ? "初始化成功" : "初始化失败"
      guard isAccessible else {
        self.popToDefalutLoginViewController()
        return
      }
      self.privacyInfo = resultInfo
      wakePage()
    }
  }
  
  private func wakeAuthPage() {
    // 第二步，唤起自定义授权页
    let selfView = UIView(frame: CGRect.init(x: 0, y: 0, width: TX_SCREEN_WIDTH, height: TX_SCREEN_HEIGHT))
    selfView.backgroundColor = UIColor.white
    setUpView(selfView)
    oneKeyLoginModel = OneKeyLoginCustomModel(selfView: selfView, loginButton: self.onekeyLoginButton!, changeTypeButton: self.changeButton!)
    oneKeyLoginModel!.loginMainViewController.title = "一键登录"
    oneKeyLoginModel?.configWeiXinButton(self.weiXinButton!)
    oneKeyLoginModel?.configQQButton(self.qqButton!)
    oneKeyLoginModel?.configWeiBoButton(self.weiBoButton!)
    oneKeyLoginModel?.configEmailButton(self.emailButton!)
    
    self.navigationController?.pushViewController(oneKeyLoginModel!.loginMainViewController, animated: true)
  }
  
  /// 点击初始化按钮进行初始化，并获取手机掩码等运营信息
  /// - Parameter sender: 按钮
  @IBAction private func startInitSDK(_ sender: UIButton) {
    setupSdk()
  }
  
  @IBAction private func getLoginMobileAndToken(_ sender: UIButton) {
    // 直接一步到打开授权页
    setupSdk(wakePage: wakeAuthPage)
  }
  
  @IBAction private func preFetchNum(_ sender: UIButton) {
    wakeAuthPage()
  }
  
  @IBAction private func onekeyLoginUI(_ sender: UIButton) {
    guard Russell.OneKeyLoginFlow.isEnable else {
      return
    }
    
    guard  let privacyInfo = Russell.OneKeyLoginFlow.privacyInfo else {
      return
    }
    
    let vc = OneKeyLoginViewController(privacyInfo: privacyInfo)
    OneKeyLoginCustomModel.configLoginButton(vc.oneKeyLoginButton)
    OneKeyLoginCustomModel.configChangeButton(vc.otherNumberLoginButton)
    Russell.OneKeyLoginFlow.startWakeAuthorizationViewController(useType: .OneKeyLogin) {
      self.navigationController?.pushViewController(vc, animated: true)
    }
  }
  
}
extension TXNumberCheckViewController: UITextViewDelegate {
  func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
    let webViewController = RussellWKWebViewController(url: URL)
    self.navigationController?.pushViewController(webViewController!, animated: true)
//    self.navigationController?.setNavigationBarHidden(true, animated: false)
    return false
  }
}

extension TXNumberCheckViewController {
  
  func setUpView(_ selfView: UIView) {
    selfView.addSubview(navBgView())
    selfView.addSubview(logoImageView())
    selfView.addSubview(sloganLabel())
    selfView.addSubview(numberLabel())
    selfView.addSubview(gotoLoginButton())
    selfView.addSubview(configChangeButton())
    selfView.addSubview(configWeiXinButton())
    selfView.addSubview(configQQButton())
    selfView.addSubview(configWeiBoButton())
    selfView.addSubview(configEmailBoButton())
    selfView.addSubview(configProtocolTextView())
  }
  
  func navBgView() -> UIView {
    let bgView = UIView(frame: CGRect.init(x: 0, y: 0, width: TX_SCREEN_WIDTH, height: TX_STATUS_NAV_BAR_HEIGHT))
    bgView.backgroundColor = UIColor.white
    return bgView
  }
  
  func logoImageView() -> UIImageView {
    topPosition = 100
    let logoImageView = UIImageView(frame: CGRect.init(x: TX_SCREEN_WIDTH/2 - 30, y: topPosition, width: 60, height: 60))
    logoImageView.image = UIImage.init(named: "lingome_app_logo", in: Bundle(for: TXNumberCheckViewController.self), compatibleWith: nil)
    return logoImageView
  }
  
  func sloganLabel() -> UILabel {
    topPosition += 100
    let sloganLabel = UILabel(frame: CGRect.init(x: 0, y: 0, width: 120.0, height: 15.0))
    sloganLabel.font = UIFont.systemFont(ofSize: 12.0)
    sloganLabel.textColor = UIColor.colorWithHexString("cccccc")
    sloganLabel.text = "中国移动认证服务"
    if self.privacyInfo?.operatorId == 2 {
      sloganLabel.text = "中国联通认证服务"
    } else if self.privacyInfo?.operatorId == 3 {
      sloganLabel.text = "中国电信认证服务"
    }
    sloganLabel.sizeToFit()
    sloganLabel.center = CGPoint(x: TX_SCREEN_WIDTH/2, y: topPosition)
    return sloganLabel
  }
  
  func numberLabel() -> UILabel {
    topPosition += 30
    let numberLabel = UILabel(frame: CGRect.init(x: 0, y: 0, width: 150.0, height: 25.0))
    numberLabel.text = self.privacyInfo?.number
    numberLabel.textColor = UIColor.black
    numberLabel.font = UIFont.boldSystemFont(ofSize: 24.0)
    numberLabel.sizeToFit()
    numberLabel.center = CGPoint(x: TX_SCREEN_WIDTH/2, y: topPosition)
    return numberLabel
  }
  
  func gotoLoginButton() -> UIButton {
    if onekeyLoginButton == nil {
      topPosition += 55
      onekeyLoginButton = UIButton(frame: CGRect.init(x: 18, y: topPosition, width: TX_SCREEN_WIDTH-2*18, height: 44.0))
      onekeyLoginButton!.setTitle("本机号码一键登录", for: .normal)
      onekeyLoginButton!.backgroundColor = UIColor.colorWithHexString("4FCB19")
      onekeyLoginButton?.layer.cornerRadius = 7
      onekeyLoginButton!.setTitleColor(UIColor.white, for: .normal)
      onekeyLoginButton!.titleLabel!.font = UIFont.systemFont(ofSize: 18.0)
      onekeyLoginButton!.addTarget(self, action: #selector(onekeyLoginClick(sender:)), for: .touchUpInside)
    }
    return onekeyLoginButton!
  }
  
  @objc func onekeyLoginClick(sender: UIButton) {
    print("onekeyLoginClick click ...")
    Russell.OneKeyLoginFlow.startGetTokenAndRequest(appID: "com.liulishuo.engzo2", fromViewController: oneKeyLoginModel!.loginMainViewController, useType: .OneKeyLogin, sessionID: "") { [weak self] (isSuccess, resultDic) in
      if isSuccess {
        let loginResult = resultDic!["data"]
        self?.popToLoginSuccessViewController(result: loginResult as! LoginResult)
      } else {
        print("login content: [\(String(describing: resultDic))]")
        self?.popToDefalutLoginViewController()
      }
    }
  }
  
  func configChangeButton() -> UIButton {
    if changeButton == nil {
      topPosition += 59
      changeButton = UIButton(frame: CGRect.init(x: TX_SCREEN_WIDTH/2 - 60, y: topPosition, width: 120.0, height: 25.0))
      changeButton!.setTitle("其他手机号登录", for: .normal)
      changeButton!.setTitleColor(UIColor.colorWithHexString("4FCB19"), for: .normal)
      changeButton!.titleLabel!.font = UIFont.systemFont(ofSize: 16.0)
      changeButton!.addTarget(self, action: #selector(changeButtonClick(sender:)), for: .touchUpInside)
    }
    return changeButton!
  }
  
  @objc func changeButtonClick(sender: UIButton) {
    print("changeButtonClick click ...")
    self.popToDefalutLoginViewController()
  }
  
  func configWeiXinButton() -> UIButton {
    if weiXinButton == nil {
      topPosition = TX_SCREEN_HEIGHT - 130
      weiXinButton = UIButton(frame: CGRect.init(x: TX_SCREEN_WIDTH/2 - 117.5, y: topPosition, width: 40.0, height: 40.0))
      weiXinButton!.setImage(UIImage.init(named: "russell_wechat_gray_l", in: Bundle(for: TXNumberCheckViewController.self), compatibleWith: nil), for: .normal)
      weiXinButton!.addTarget(self, action: #selector(weiXinButtonClick(sender:)), for: .touchUpInside)
    }
    return weiXinButton!
  }
  
  @objc func weiXinButtonClick(sender: UIButton) {
    print("weiXinButtonClick click ...")
    self.popToDefalutLoginViewController()
  }
  
  func configQQButton() -> UIButton {
    if qqButton == nil {
      qqButton = UIButton(frame: CGRect.init(x: weiXinButton!.frame.origin.x + 65, y: topPosition, width: 40.0, height: 40.0))
      qqButton!.setImage(UIImage.init(named: "russell_qq_gray_l", in: Bundle(for: TXNumberCheckViewController.self), compatibleWith: nil), for: .normal)
      qqButton!.addTarget(self, action: #selector(qqButtonClick(sender:)), for: .touchUpInside)
    }
    return qqButton!
  }
  
  @objc func qqButtonClick(sender: UIButton) {
    print("qqButtonClick click ...")
    self.popToDefalutLoginViewController()
  }
  
  func configWeiBoButton() -> UIButton {
    if weiBoButton == nil {
      weiBoButton = UIButton(frame: CGRect.init(x: qqButton!.frame.origin.x + 65, y: topPosition, width: 40.0, height: 40.0))
      weiBoButton!.setImage(UIImage.init(named: "russell_weibo_gray_l", in: Bundle(for: TXNumberCheckViewController.self), compatibleWith: nil), for: .normal)
      weiBoButton!.addTarget(self, action: #selector(weiBoButtonClick(sender:)), for: .touchUpInside)
    }
    return weiBoButton!
  }
  
  @objc func weiBoButtonClick(sender: UIButton) {
    print("weiBoButtonClick click ...")
    self.popToDefalutLoginViewController()
  }
  
  func configEmailBoButton() -> UIButton {
    if emailButton == nil {
      emailButton = UIButton(frame: CGRect.init(x: weiBoButton!.frame.origin.x + 65, y: topPosition, width: 40.0, height: 40.0))
      emailButton!.setImage(UIImage.init(named: "russell_mail_gray_l", in: Bundle(for: TXNumberCheckViewController.self), compatibleWith: nil), for: .normal)
      emailButton!.addTarget(self, action: #selector(emailButtonClick(sender:)), for: .touchUpInside)
    }
    return emailButton!
  }
  
  @objc func emailButtonClick(sender: UIButton) {
    print("emailButtonClick click ...")
    self.popToDefalutLoginViewController()
  }
  
  func configProtocolTextView() -> UITextView {
    topPosition += 60
    if protocolTextView == nil {
      protocolTextView = UITextView(frame: CGRect.init(x: 16, y: topPosition, width: TX_SCREEN_WIDTH - 32, height: 0))
      protocolTextView!.textAlignment = .center
      protocolTextView!.isEditable = false
      protocolTextView!.textColor = UIColor.colorWithHexString("aaaaaa")
      protocolTextView!.font = UIFont.systemFont(ofSize: 14.0)
      let contentStr = "登录即代表同意\(privacyInfo!.privacyName)以及《服务使用协议》和《隐私政策》"
      let contentNSStr = NSString(string: contentStr)
      let attrStr = NSMutableAttributedString.init(string: contentStr)
      let privacyRange = contentNSStr.range(of: privacyInfo!.privacyName)
      let serviceRange = contentNSStr.range(of: "《服务使用协议》")
      let privateRange = contentNSStr.range(of: "《隐私政策》")
      print("privacyInfo!.privacyUrl:", privacyInfo!.privacyUrl)
      let paragraph = NSMutableParagraphStyle.init()
      paragraph.lineSpacing = 8
      attrStr.addAttribute(.paragraphStyle, value: paragraph, range: NSRange.init(location: 0, length: contentStr.count))
      attrStr.addAttributes([
        .foregroundColor: UIColor.colorWithHexString("757575"),
        .link: NSURL(string: privacyInfo!.privacyUrl) as Any
      ], range: privacyRange)
      attrStr.addAttributes([
        .foregroundColor: UIColor.colorWithHexString("757575"),
        .link: NSURL(string: "https://www.baidu.com") as Any
      ], range: serviceRange)
      attrStr.addAttributes([
        .foregroundColor: UIColor.colorWithHexString("757575"),
        .link: NSURL(string: privacyInfo!.privacyUrl) as Any
      ], range: privateRange)
      protocolTextView!.attributedText = attrStr
      protocolTextView!.sizeToFit()
      protocolTextView!.center = CGPoint(x: TX_SCREEN_WIDTH/2, y: topPosition + protocolTextView!.frame.size.height/2)
    }
    protocolTextView?.delegate = self
    return protocolTextView!
  }
  
  func popToDefalutLoginViewController() {
    let defalutVC = UIViewController()
    defalutVC.view.backgroundColor = UIColor.red
    defalutVC.title = "登录"
    self.navigationController?.pushViewController(defalutVC, animated: true)
    //    self.navigationController?.viewControllers.insert(defalutVC, at: 0)
    //    self.navigationController?.popToViewController(defalutVC, animated: true)
  }
  
  func popToLoginSuccessViewController(result: LoginResult) {
    let successVC = UIViewController()
    successVC.view.backgroundColor = UIColor.white
    successVC.title = "首页"
    let mobileLabel = UILabel()
    mobileLabel.frame = CGRect(origin: CGPoint(x: UIScreen.main.bounds.size.width/2 - 100, y: 100), size: CGSize(width: 200, height: 30))
    mobileLabel.text = result.mobile ?? "号码为空"
    successVC.view.addSubview(mobileLabel)
    self.navigationController?.pushViewController(successVC, animated: true)
    //    self.navigationController?.viewControllers.insert(successVC, at: 0)
    //    self.navigationController?.popToViewController(successVC, animated: true)
  }
}
