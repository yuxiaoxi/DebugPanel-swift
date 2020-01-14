//
//  OneKeyLoginViewController.swift
//  RussellUIForDemo
//
//  Created by zhuo yu on 2019/10/25.
//  Copyright © 2019 LLS. All rights reserved.
//

import Russell
import UIKit

public final class OneKeyLoginViewController: UIViewController {
  // MARK: - Properties
  
  private let privacyInfo: OneKeyPrivacyConfigModel
  
  private let logoImageView = UIImageView()
  private let mobileCommunicationOperatorLabel = UILabel()
  private let phoneNumberLabel = UILabel()
  private let privacyTextView = UITextView()
  let oneKeyLoginButton = UIButton(frame: CGRect.init(x: 18, y: 0, width: TX_SCREEN_WIDTH-2*18, height: 44.0))
  let otherNumberLoginButton = UIButton(frame: CGRect.init(x: 18, y: 0, width: TX_SCREEN_WIDTH-2*18, height: 20.0))
  
  // MARK: - Initializers
  
  public required init(privacyInfo: OneKeyPrivacyConfigModel) {
    self.privacyInfo = privacyInfo
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - View Life Cycle
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    self.modalPresentationStyle = .fullScreen
    setupUI()
  }
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.navigationBar.alpha = 0
  }
  
  public override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.navigationBar.alpha = 1
  }
}

// MARK: setup view methods

extension OneKeyLoginViewController {
  private func setupUI() {
    view.backgroundColor = .white
    
    logoImageView.image = UIImage(named: "lingome_app_logo", in: Bundle(for: TXNumberCheckViewController.self), compatibleWith: nil)
    logoImageView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(logoImageView)
    NSLayoutConstraint.activate([
      logoImageView.topAnchor.constraint(equalTo: view.realSafeAreaLayoutGuide.topAnchor, constant: 85),
      logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      logoImageView.widthAnchor.constraint(equalToConstant: 64.0),
      logoImageView.heightAnchor.constraint(equalToConstant: 64.0)
    ])
    
    mobileCommunicationOperatorLabel.text = "中国移动认证服务"
    mobileCommunicationOperatorLabel.font = .systemFont(ofSize: 12.0)
    mobileCommunicationOperatorLabel.textColor = .llsFcTips
    mobileCommunicationOperatorLabel.textAlignment = .center
    mobileCommunicationOperatorLabel.setContentHuggingPriority(.required, for: .vertical)
    if privacyInfo.operatorId == 2 {
      mobileCommunicationOperatorLabel.text = "中国联通认证服务"
    } else if privacyInfo.operatorId == 3 {
      mobileCommunicationOperatorLabel.text = "中国电信认证服务"
    }
    
    phoneNumberLabel.text = privacyInfo.number
    phoneNumberLabel.font = .systemFont(ofSize: 24, weight: .semibold)
    phoneNumberLabel.textColor = .black
    phoneNumberLabel.textAlignment = .center
    phoneNumberLabel.setContentHuggingPriority(.required, for: .vertical)
    
    let phoneStackView = UIStackView(arrangedSubviews: [mobileCommunicationOperatorLabel, phoneNumberLabel])
    phoneStackView.axis = .vertical
    phoneStackView.distribution = .equalSpacing
    phoneStackView.alignment = .center
    phoneStackView.spacing = 5.0
    phoneStackView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(phoneStackView)
    NSLayoutConstraint.activate([
      phoneStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      phoneStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      phoneStackView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 40)
    ])
    
    oneKeyLoginButton.setTitle("本机号码一键登录", for: .normal)
    oneKeyLoginButton.setTitleColor(.white, for: .normal)
    oneKeyLoginButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
    oneKeyLoginButton.backgroundColor = .llsGreen
    oneKeyLoginButton.addTarget(self, action: #selector(onekeyLoginClick(sender:)), for: .touchUpInside)
    oneKeyLoginButton.layer.cornerRadius = 7.0
    oneKeyLoginButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(oneKeyLoginButton)
    NSLayoutConstraint.activate([
      oneKeyLoginButton.topAnchor.constraint(equalTo: phoneStackView.bottomAnchor, constant: 40),
      oneKeyLoginButton.heightAnchor.constraint(equalToConstant: 44.0),
      oneKeyLoginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      oneKeyLoginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
    ])
    
    otherNumberLoginButton.setTitle("其他登录方式", for: .normal)
    otherNumberLoginButton.setTitleColor(.llsGreen, for: .normal)
    otherNumberLoginButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
    otherNumberLoginButton.backgroundColor = .clear
    otherNumberLoginButton.addTarget(self, action: #selector(changeButtonClick(sender:)), for: .touchUpInside)
    otherNumberLoginButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(otherNumberLoginButton)
    NSLayoutConstraint.activate([
      otherNumberLoginButton.topAnchor.constraint(equalTo: oneKeyLoginButton.bottomAnchor, constant: 20),
      otherNumberLoginButton.centerXAnchor.constraint(equalTo: oneKeyLoginButton.centerXAnchor)
    ])
    
    privacyTextView.delegate = self
    privacyTextView.isEditable = false
//    privacyTextView.isSelectable = false
    privacyTextView.isScrollEnabled = false
    privacyTextView.attributedText = configurePrivacyAttributedString()
    privacyTextView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(privacyTextView)
    NSLayoutConstraint.activate([
      privacyTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
      privacyTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
      privacyTextView.bottomAnchor.constraint(equalTo: view.realSafeAreaLayoutGuide.bottomAnchor, constant: -14),
      privacyTextView.heightAnchor.constraint(equalToConstant: 52)
    ])
  }
  
  @objc func onekeyLoginClick(sender: UIButton) {
    print("onekeyLoginClick click ...")
    Russell.OneKeyLoginFlow.startGetTokenAndRequest(appID: "com.liulishuo.engzo2", fromViewController: self, useType: .OneKeyLogin, sessionID: "") { [weak self] isSuccess, resultDic in
      if isSuccess {
        let loginResult = resultDic!["data"]
        self?.popToLoginSuccessViewController(result: loginResult as! LoginResult)
      } else {
        print("login content: [\(String(describing: resultDic))]")
        self?.popToDefalutLoginViewController()
      }
    }
  }
  
  @objc func changeButtonClick(sender: UIButton) {
    print("changeButtonClick click ...")
    popToDefalutLoginViewController()
  }
  
  private func configurePrivacyAttributedString() -> NSAttributedString {
    let contentStr = """
    登录即代表同意\(privacyInfo.privacyName)以及
    《服务使用协议》和《隐私政策》
    """
    
    let contentNSStr = NSString(string: contentStr)
    let attrStr = NSMutableAttributedString(string: contentStr)
    let privacyRange = contentNSStr.range(of: privacyInfo.privacyName)
    let serviceRange = contentNSStr.range(of: "《服务使用协议》")
    let privateRange = contentNSStr.range(of: "《隐私政策》")
    
    let fullRange = NSRange(location: 0, length: contentStr.count)
    
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineSpacing = 6
    attrStr.addAttribute(.paragraphStyle, value: paragraph, range: fullRange)
    
    attrStr.addAttributes([
      .font: UIFont.systemFont(ofSize: 12),
      .foregroundColor: UIColor.llsGray4
    ], range: fullRange)
    attrStr.addAttributes([
      .foregroundColor: UIColor.ccBlue,
      .link: NSURL(string: privacyInfo.privacyUrl) as Any
    ], range: privacyRange)
    attrStr.addAttributes([
      .foregroundColor: UIColor.ccBlue,
      .link: NSURL(string: "https://www.baidu.com") as Any
    ], range: serviceRange)
    attrStr.addAttributes([
      .foregroundColor: UIColor.ccBlue,
      .link: NSURL(string: privacyInfo.privacyUrl) as Any
    ], range: privateRange)
    
    return NSAttributedString(attributedString: attrStr)
  }
  
  private func popToDefalutLoginViewController() {
    let defalutVC = UIViewController()
    defalutVC.view.backgroundColor = .red
    defalutVC.title = "登录"
    navigationController?.pushViewController(defalutVC, animated: true)
  }
  
  private func popToLoginSuccessViewController(result: LoginResult) {
    let successVC = UIViewController()
    successVC.view.backgroundColor = .white
    successVC.title = "首页"
    let mobileLabel = UILabel()
    mobileLabel.frame = CGRect(origin: CGPoint(x: UIScreen.main.bounds.size.width / 2 - 100, y: 100), size: CGSize(width: 200, height: 30))
    mobileLabel.text = result.mobile ?? "号码为空"
    successVC.view.addSubview(mobileLabel)
    navigationController?.pushViewController(successVC, animated: true)
  }
}

// MARK: - extend UITextViewDelegate

extension OneKeyLoginViewController: UITextViewDelegate {
  public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
    let webViewController = RussellWKWebViewController(url: URL)
    self.navigationController?.present(webViewController!, animated: true, completion: nil)
    return false
  }
}

// MARK: - Layout Bug Fix

protocol LayoutGuideProvider {
  var leadingAnchor: NSLayoutXAxisAnchor { get }
  var trailingAnchor: NSLayoutXAxisAnchor { get }
  var leftAnchor: NSLayoutXAxisAnchor { get }
  var rightAnchor: NSLayoutXAxisAnchor { get }
  var topAnchor: NSLayoutYAxisAnchor { get }
  var bottomAnchor: NSLayoutYAxisAnchor { get }
  var widthAnchor: NSLayoutDimension { get }
  var heightAnchor: NSLayoutDimension { get }
  var centerXAnchor: NSLayoutXAxisAnchor { get }
  var centerYAnchor: NSLayoutYAxisAnchor { get }
}

extension UIView: LayoutGuideProvider {}
extension UILayoutGuide: LayoutGuideProvider {}

extension UIView {
  var realSafeAreaLayoutGuide: LayoutGuideProvider {
    if #available(iOS 11, *), responds(to: #selector(getter: UIView.safeAreaLayoutGuide)) {
      return safeAreaLayoutGuide
    } else {
      return self
    }
  }
}

extension UIColor {
  static let llsGreen = UIColor(red: 79.0 / 255.0, green: 203.0 / 255.0, blue: 25.0 / 255.0, alpha: 1.0)
  static let llsFcTips = UIColor(white: 204.0 / 255.0, alpha: 1.0)
  static let llsGray4 = UIColor(white: 179.0 / 255.0, alpha: 1.0)
  static let ccBlue = UIColor(red: 27.0 / 255.0, green: 156.0 / 255.0, blue: 253.0 / 255.0, alpha: 1.0)
}
