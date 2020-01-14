//
//  OneKeyBinderViewController.swift
//  Russell
//
//  Created by zhuo yu on 2019/10/24.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit

final class OneKeyBinderViewController: UIViewController, _Trackable, HeadsUpDisplayable {
  private let privacyInfo: OneKeyPrivacyConfigModel // 一键登录 SDK 返回的运营商信息
  let onekeyLoginButton = UIButton(frame: CGRect(x: 20, y: 0, width: TX_SCREEN_WIDTH - 40, height: 44.0))
  let changeButton = UIButton(frame: CGRect(x: 20, y: 0, width: TX_SCREEN_WIDTH - 40, height: 44.0))
  private let headerLabel = UILabel()
  private let detailLabel = UILabel()
  private let sloganLabel = UILabel()
  private let numberLabel = UILabel()
  private let protocolTextView = UITextView()
  private let sessionID: String
  private let isSignup: Bool
  private weak var delegate: OneKeyBinderSessionDelegate?
  var binderBlock: (_ container: Russell.UI.Container, _ sessionID: String, _ isNewRegister: Bool, _ canBack: Bool, _ source: BindMobileTracking.Source) -> Void
  
  public required init?(privacyInfo: OneKeyPrivacyConfigModel, sessionID: String, isSignup: Bool = false, delegate: OneKeyBinderSessionDelegate, binderBlock: @escaping(_ container: Russell.UI.Container, _ sessionID: String, _ isNewRegister: Bool, _ canBack: Bool, _ source: BindMobileTracking.Source) -> Void) {
    self.privacyInfo = privacyInfo
    self.sessionID = sessionID
    self.isSignup = isSignup
    self.delegate = delegate
    self.binderBlock = binderBlock
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    _setUpView()
  }
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  public override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
  }
}

// MARK: extend UITextViewDelegate

extension OneKeyBinderViewController: UITextViewDelegate {
  public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
    let webViewController = RussellWKWebViewController(url: URL)
    navigationController?.present(webViewController!, animated: true, completion: nil)
    return false
  }
}

// MARK: setup view methods

extension OneKeyBinderViewController {
  private func _setUpView() {
    view.backgroundColor = UIColor.white
    buildHeaderLabel()
    buildDetailLabel()
    buildSloganLabel()
    buildNumberLabel()
    gotoLoginButton()
    configChangeButton()
    configProtocolTextView()
  }
  
  private func buildHeaderLabel() {
    headerLabel.font = Russell.UI.theme.mediumFont.withSize(24)
    headerLabel.textColor = Russell.UI.theme.textColor.titleColor
    headerLabel.text = _UISafeLocalizedString(for: "Input-Mobile-Bind-Header")
    headerLabel.textAlignment = .left
    headerLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(headerLabel)
    NSLayoutConstraint.activate([
      headerLabel.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 40),
      headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
    ])
  }
  
  private func buildDetailLabel() {
    detailLabel.numberOfLines = 0
    detailLabel.font = Russell.UI.theme.font.withSize(14)
    detailLabel.textColor = UIColor(white: 117.0 / 255.0, alpha: 1.0)
    detailLabel.text = _UISafeLocalizedString(for: "Input-Mobile-Bind-Detail")
    detailLabel.textAlignment = .left
    detailLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(detailLabel)
    detailLabel.setContentHuggingPriority(.required, for: .vertical)
    detailLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    NSLayoutConstraint.activate([
      detailLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      detailLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      detailLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 5)
    ])
  }
  
  private func buildSloganLabel() {
    sloganLabel.text = "中国移动认证"
    if privacyInfo.operatorId == 2 {
      sloganLabel.text = "中国联通认证"
    } else if privacyInfo.operatorId == 3 {
      sloganLabel.text = "中国电信认证"
    }
    sloganLabel.font = UIFont.systemFont(ofSize: 12.0)
    sloganLabel.textColor = UIColor.colorWithHexString("cccccc")
    sloganLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(sloganLabel)
    NSLayoutConstraint.activate([
      sloganLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      sloganLabel.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 40)
    ])
  }
  
  private func buildNumberLabel() {
    numberLabel.text = privacyInfo.number
    numberLabel.textColor = UIColor.black
    numberLabel.font = UIFont.systemFont(ofSize: 24.0, weight: .semibold)
    numberLabel.textAlignment = .center
    numberLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(numberLabel)
    NSLayoutConstraint.activate([
      numberLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      numberLabel.topAnchor.constraint(equalTo: sloganLabel.bottomAnchor, constant: 5)
    ])
  }
  
  private func gotoLoginButton() {
    onekeyLoginButton.setTitle("绑定手机号", for: .normal)
    onekeyLoginButton.backgroundColor = UIColor.colorWithHexString("4FCB19")
    onekeyLoginButton.layer.cornerRadius = 7
    onekeyLoginButton.setTitleColor(UIColor.white, for: .normal)
    onekeyLoginButton.titleLabel?.font = UIFont.systemFont(ofSize: 18.0, weight: .semibold)
    onekeyLoginButton.addTarget(self, action: #selector(onekeyLoginClick(sender:)), for: .touchUpInside)
    onekeyLoginButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(onekeyLoginButton)
    NSLayoutConstraint.activate([
      onekeyLoginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      onekeyLoginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      onekeyLoginButton.heightAnchor.constraint(equalToConstant: 44.0),
      onekeyLoginButton.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 40)
    ])
  }
  
  @objc func onekeyLoginClick(sender: UIButton) {
    guard sender.isEnabled else {
      return
    }
    
    sender.isEnabled = false
    self.headsUpDisplay?.show()
    Russell.OneKeyLoginFlow.startGetTokenAndBinder(fromViewController: self, useType: .OneKeyBinder, sessionID: sessionID, isSignup: isSignup, delegate: delegate!) { [weak self] isSuccess, resultDic in
      guard let self = self else { return }
      
      if !isSuccess {
        self.headsUpDisplay?.dismiss()
        Logger.info("login content: [\(String(describing: resultDic))]")
        self.headsUpDisplay?.showError("绑定失败，请重新绑定")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
          self.headsUpDisplay?.dismiss()
          self.binderBlock(Russell.UI.Container.presentation(self), self.sessionID, self.isSignup, false, .oneBindingFailed)
        }
      } else {
        self.headsUpDisplay?.dismiss()
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        sender.isEnabled = true
      }
    }
  }
  
  private func configChangeButton() {
    changeButton.setTitle("绑定其他手机号", for: .normal)
    changeButton.setTitleColor(UIColor.colorWithHexString("4FCB19"), for: .normal)
    changeButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
    changeButton.addTarget(self, action: #selector(changeButtonClick(sender:)), for: .touchUpInside)
    changeButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(changeButton)
    NSLayoutConstraint.activate([
      changeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      changeButton.topAnchor.constraint(equalTo: onekeyLoginButton.bottomAnchor, constant: 20)
    ])
  }
  
  @objc func changeButtonClick(sender: UIButton) {
    guard sender.isEnabled else {
      return
    }
    
    sender.isEnabled = false
    binderBlock(Russell.UI.Container.presentation(self), sessionID, isSignup, true, .oneBindingSwitch)
    sender.isEnabled = true
  }
  
  private func configProtocolTextView() {
    var frame = CGRect(x: 30, y: TX_SCREEN_HEIGHT - 70 - TX_STATUS_NAV_BAR_HEIGHT, width: TX_SCREEN_WIDTH - 60, height: 0)
    protocolTextView.frame = frame
    protocolTextView.backgroundColor = .white
    protocolTextView.isEditable = false
    protocolTextView.isScrollEnabled = false
    protocolTextView.attributedText = configPrivacyAttributedString()
    protocolTextView.sizeToFit()
    frame = protocolTextView.frame
    protocolTextView.center = CGPoint(x: TX_SCREEN_WIDTH / 2, y: frame.minY + frame.height / 2)
    protocolTextView.delegate = self
    view.addSubview(protocolTextView)
  }
  
  private func configPrivacyAttributedString() -> NSAttributedString {
    let contentStr = """
    绑定即代表同意\(privacyInfo.privacyName)以及
    《服务使用协议》和《隐私政策》并使用本机号码登录
    """
    let contentNSStr = NSString(string: contentStr)
    let attrStr = NSMutableAttributedString(string: contentStr)
    let privacyRange = contentNSStr.range(of: privacyInfo.privacyName)
    let serviceRange = contentNSStr.range(of: "《服务使用协议》")
    let privateRange = contentNSStr.range(of: "《隐私政策》")
    
    let fullRange = NSRange(location: 0, length: contentStr.count)
    
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineSpacing = 8
    attrStr.addAttribute(.paragraphStyle, value: paragraph, range: fullRange)
    
    let bundle = Bundle(for: OneKeyBinderViewController.self)
    let agreementHTML = bundle.url(forResource: "user_service_agreement", withExtension: "html")!
    let privacyHTML = bundle.url(forResource: "user_privacy", withExtension: "html")!
    
    attrStr.addAttributes([
      .font: UIFont.systemFont(ofSize: 12),
      .foregroundColor: UIColor(white: 179.0 / 255.0, alpha: 1.0)
    ], range: fullRange)
    attrStr.addAttributes([
      .foregroundColor: UIColor.colorWithHexString("757575"),
      .link: NSURL(string: privacyInfo.privacyUrl) as Any
    ], range: privacyRange)
    attrStr.addAttributes([
      .foregroundColor: UIColor.colorWithHexString("757575"),
      .link: agreementHTML
    ], range: serviceRange)
    attrStr.addAttributes([
      .foregroundColor: UIColor.colorWithHexString("757575"),
      .link: privacyHTML
    ], range: privateRange)
    
    return NSAttributedString(attributedString: attrStr)
  }
}
