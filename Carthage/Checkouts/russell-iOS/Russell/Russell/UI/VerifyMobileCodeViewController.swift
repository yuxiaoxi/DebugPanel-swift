//
//  VerifyMobileCodeViewController.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/7/22.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit

protocol VerifyMobileCodeDelegate: class {
  func verify(code: String)
  func resendVerificationCode()
  func cancelMobileCodeInput()
}

final class VerifyMobileCodeViewController: UIViewController, _Trackable {
  
  var mobile = ""
  var initialTimeout: Int?
  weak var delegate: VerifyMobileCodeDelegate?
  
  private weak var codeField: VerificationCodeField!
  private weak var resendButton: UIButton!
  
  @objc private func _back(_ sender: UIBarButtonItem) {
    self.endTextEditing()
    RealNameCertificationAlert.waitForDelayedMobileCode.show(
      in: self,
      confirmTrack: nil,
      cancelTrack: nil,
      cancelAction: { self.beginTextEditing() },
      completion: { self.delegate?.cancelMobileCodeInput() }
    )
  }
  
  @objc private func _verify(_ sender: VerificationCodeField) {
    tracker?.action(actionName: "submit_validation_code", properties: nil)
    delegate?.verify(code: sender.text)
  }
  
  @objc private func _resend(_ sender: UIButton) {
    tracker?.action(actionName: "click_resend_validation_code", properties: nil)
    delegate?.resendVerificationCode()
    _startCountdownTimer()
    clearCode()
  }
  
  private func clearCode() {
    codeField.text = ""
  }
  
  // MARK: - Life Cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    hidesBottomBarWhenPushed = true
    
    view.backgroundColor = .white
    edgesForExtendedLayout = []
    _buildContent()
    _setupAction()
    initialTimeout.map(self._startCountdownTimer)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    tracker?.enter(page: "retrieve_validation_code", properties: nil)
    codeField.becomeFirstResponder()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    codeField.resignFirstResponder()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    _stopCountdownTimer()
  }
  
  // MARK: - Timer
  
  private var _disableTime = 0
  private func _decreaseDisableTime() {
    _disableTime -= 1
    if _disableTime <= 0 {
      resendButton.isEnabled = true
    } else {
      _updateResendButtonDisableTitle()
    }
  }
  
  @inline(__always)
  private func _updateResendButtonDisableTitle() {
    resendButton.setTitle(String.localizedStringWithFormat("%d 秒后可重新发送", _disableTime), for: .disabled)
  }
  
  private weak var _timer: Timer? {
    didSet { oldValue?.invalidate() }
  }
  
  private func _startCountdownTimer(timeout: Int = 60) {
    _disableTime = timeout
    resendButton.isEnabled = false
    _updateResendButtonDisableTitle()
    
    let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
      self?._decreaseDisableTime()
    }
    RunLoop.main.add(timer, forMode: .common)
    _timer = timer
  }
  
  private func _stopCountdownTimer() {
    _timer = nil
  }
  
  // MARK: - Builder
  
  private var keyboardReactor: ScrollViewKeyboardReactor?
  
  private func _buildContent() {
    
    let (reactor, view) = ScrollViewKeyboardReactor.buildContentScrollViewWithReactorInContainer(self.view)
    keyboardReactor = reactor
    
    let headerLabel = UILabel()
    headerLabel.translatesAutoresizingMaskIntoConstraints = false
    headerLabel.font = Russell.UI.theme.mediumFont.withSize(24)
    headerLabel.textColor = Russell.UI.theme.textColor.titleColor
    headerLabel.text = _UISafeLocalizedString(for: "Verify-Mobile-Code-Header")
    view.addSubview(headerLabel)
    
    let mobileLabel = UILabel()
    mobileLabel.translatesAutoresizingMaskIntoConstraints = false
    mobileLabel.font = Russell.UI.theme.font.withSize(14)
    mobileLabel.textColor = Russell.UI.theme.textColor.contentColor
    mobileLabel.text = String.localizedStringWithFormat(_UISafeLocalizedString(for: "Verify-Mobile-Code-Detail-Format"), mobile)
    view.addSubview(mobileLabel)
    
    let codeField = VerificationCodeField()
    codeField.translatesAutoresizingMaskIntoConstraints = false
    codeField.addTarget(self, action: #selector(_verify(_:)), for: .primaryActionTriggered)
    self.codeField = codeField
    view.addSubview(codeField)
    
    let button = UIButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.titleLabel?.font = Russell.UI.theme.button.font
    button.setTitle(_UISafeLocalizedString(for: "Verify-Mobile-Code-Resend"), for: .normal)
    button.setTitleColor(Russell.UI.theme.tintColor, for: .normal)
    button.setTitleColor(Russell.UI.theme.button.disabledTitleColor, for: .disabled)
    button.addTarget(self, action: #selector(_resend(_:)), for: .touchUpInside)
    resendButton = button
    view.addSubview(button)
    
    NSLayoutConstraint.activate([
      headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Russell.UI.sidePadding),
      headerLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
      headerLabel.heightAnchor.constraint(equalToConstant: 33),
      
      mobileLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Russell.UI.sidePadding),
      mobileLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 5),
      mobileLabel.heightAnchor.constraint(equalToConstant: 20),
      
      codeField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Russell.UI.sidePadding),
      codeField.topAnchor.constraint(equalTo: mobileLabel.bottomAnchor, constant: 50),
      
      button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Russell.UI.sidePadding),
      button.topAnchor.constraint(equalTo: codeField.bottomAnchor, constant: 30),
      button.heightAnchor.constraint(equalToConstant: 27),
      view.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: 20)
      ])
  }
  
  private func _setupAction() {
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      image: UIImage(named: "ic-back", in: Bundle(for: VerifyMobileCodeViewController.self), compatibleWith: nil),
      style: .plain,
      target: self,
      action: #selector(_back(_:)))
  }
}

// MARK: - Text Editing

extension VerifyMobileCodeViewController: TextInputContainer {
  
  func beginTextEditing() {
    codeField.becomeFirstResponder()
  }
  
  func endTextEditing() {
    codeField.resignFirstResponder()
  }
}
