//
//  MobileInputViewController.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/7/22.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit

protocol MobileInputDelegate: class {
  
  func presentAreaCodePicker()
  func isValidMobile(_ mobile: String) -> Bool
  func verify(mobile: String)
  func performExternalAction(_ action: @escaping (_ container: UINavigationController) -> Void)
  func cancelBinding()
}

private let privacyDummyURL = URL(string: "platform-russell:///privacy")!

final class MobileInputViewController: UIViewController, _Trackable {
  //swiftlint:disable weak_delegate
  var delegate: MobileInputDelegate?
  //swiftlint:enable weak_delegate
  private var privacyAction: ((_ container: UINavigationController) -> Void)?
  
  private var keyboardReactor: ScrollViewKeyboardReactor?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    hidesBottomBarWhenPushed = true
    
    edgesForExtendedLayout = []
    view.backgroundColor = .white
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    tracker?.enter(page: "binding_number", properties: nil)
    
    mobileField?.becomeFirstResponder()
  }
  
  // input
  
  private weak var mobileField: UITextField?
  
  private var mobile: String?
  
  func clearMobile() {
    mobileField?.text = nil
    mobile = nil
    confirmButton?.isEnabled = false
  }
  
  @objc private func _updateMobile(_ sender: UITextField) {
    mobile = sender.text
    _updateConfirmButtonStatus()
  }
  
  // area code selector
  
  private weak var areaCodeButton: AreaCodeButton?
  
  @objc private func _selectAreaCode(_ sender: AreaCodeButton) {
    sender.setIsOn(true, animated: true)
    delegate?.presentAreaCodePicker()
  }
  
  func updateSelection(_ dialCode: String) {
    tracker?.action(actionName: "selected_country", properties: nil)
    
    areaCodeButton?.updateContent(dialCode, animated: true)
    _updateConfirmButtonStatus()
  }
  
  func areaCodePickerDismissed() {
    areaCodeButton?.setIsOn(false, animated: true)
  }
  
  // confirm action
  
  private weak var confirmButton: UIButton?
  
  @objc private func _next(_ sender: AnyObject) {
    guard let mobile = mobile, !mobile.isEmpty else { return }
    
    tracker?.action(actionName: "click_next_button", properties: nil)
    delegate?.verify(mobile: mobile)
  }
  
  private func _updateConfirmButtonStatus() {
    confirmButton?.isEnabled = delegate?.isValidMobile(mobile ?? "") ?? false
  }
  
  // cancel action
  
  @objc private func _cancel(_ sender: UIBarButtonItem) {
    delegate?.cancelBinding()
  }
}

extension MobileInputViewController: TextInputContainer {
  func beginTextEditing() {
    mobileField?.becomeFirstResponder()
  }
  
  func endTextEditing() {
    mobileField?.resignFirstResponder()
  }
}

// MARK: - UITextFieldDelegate

extension MobileInputViewController: UITextFieldDelegate {
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    if string.contains(where: { !CharacterSet.decimalDigits.contains($0.unicodeScalars.first!) }) {
      return false
    }
    
    if (textField.text?.count ?? 0) + string.count - range.length > 11 { // length exceeds 11
      return false
    }
    
    return true
  }
}

// MARK: - UITextViewDelegate

extension MobileInputViewController: UITextViewDelegate {
  
  func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
    switch interaction {
    case .presentActions, .preview:
      return false
    case .invokeDefaultAction where URL == privacyDummyURL:
      if let privacyAction = privacyAction {
        tracker?.action(actionName: "click_hyperlink_privacy_policy", properties: nil)
        delegate?.performExternalAction(privacyAction)
      }
      return false
    default:
      return false
    }
  }
}

// MARK: - Builder

extension MobileInputViewController {
  
  func setup(configuration: BindMobileConfiguration, initialDialCode: String) {
    let header: String
    let detail: NSAttributedString
    
    if configuration.isRebinding {
      header = _UISafeLocalizedString(for: "Input-Mobile-Rebind-Header")
      if let message = configuration.hintMessage {
        detail = _attributedDetail(content: message)
      } else if configuration.isExpired {
        detail = _attributedDetail(key: "Input-Mobile-Rebind-Detail-Expired")
      } else {
        detail = _attributedDetail(key: "Input-Mobile-Rebind-Detail-Normal")
      }
    } else if configuration.privacyInfo?.hasUserConfirmed == false, let action = configuration.privacyInfo?.action {
      privacyAction = action
      header = _UISafeLocalizedString(for: "Input-Mobile-Privacy-Header")
      detail = _linkedAttributeDetail(formatKey: "Input-Mobile-Privacy-Detail-Formatter", linkTextKey: "Input-Mobile-Privacy", link: privacyDummyURL)
    } else {
      header = _UISafeLocalizedString(for: "Input-Mobile-Bind-Header")
      detail = _attributedDetail(key: "Input-Mobile-Bind-Detail")
    }
    
    build(header: header, detail: detail, initialDialCode: initialDialCode)
    
    if configuration.isCancellable {
      let item = UIBarButtonItem(image: UIImage(named: "ic-back", in: Bundle(for: MobileInputViewController.self), compatibleWith: nil), style: .plain, target: self, action: #selector(_cancel(_:)))
      navigationItem.leftBarButtonItem = item
    } else {
      navigationItem.leftBarButtonItem = nil
    }
  }
  
  private func _attributedDetail(key: String) -> NSAttributedString {
    return _attributedDetail(content: _UISafeLocalizedString(for: key))
  }
  
  private func _attributedDetail(content: String) -> NSAttributedString {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineHeightMultiple = 1.5
    return NSAttributedString(
      string: content,
      attributes: [
        .font: Russell.UI.theme.font.withSize(14),
        .foregroundColor: Russell.UI.theme.textColor.contentColor,
        .paragraphStyle: paragraphStyle
      ])
  }
  
  private func _linkedAttributeDetail(formatKey: String, linkTextKey: String, link: URL) -> NSAttributedString {
    let content = NSMutableAttributedString(attributedString: _attributedDetail(key: formatKey))
    
    while true {
      let targetRange = (content.string as NSString).range(of: "%LINK%")
      if targetRange.location == NSNotFound { break }
      
      let replacement = NSMutableAttributedString(attributedString: _attributedDetail(key: linkTextKey))
      replacement.setAttributes([.link: link, .foregroundColor: Russell.UI.theme.tintColor], range: NSRange(location: 0, length: replacement.length))
      
      content.replaceCharacters(in: targetRange, with: replacement)
    }
    
    return NSAttributedString(attributedString: content)
  }
  
  private func build(header: String, detail: NSAttributedString, initialDialCode: String) {
    
    let (reactor, container) = ScrollViewKeyboardReactor.buildContentScrollViewWithReactorInContainer(view)
    keyboardReactor = reactor
    
    let headerLabel = _buildHeaderLabel()
    headerLabel.text = header
    container.addSubview(headerLabel)
    
    let detailLabel = _buildDetailLabel()
    detailLabel.attributedText = detail
    container.addSubview(detailLabel)
    
    let inputView = _buildInputView(initialDialCode: initialDialCode)
    container.addSubview(inputView)
    
    let confirmButton = _buildConfirmButton()
    self.confirmButton = confirmButton
    container.addSubview(confirmButton)
    
    NSLayoutConstraint.activate([
      headerLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Russell.UI.sidePadding),
      headerLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 40),
      container.trailingAnchor.constraint(equalTo: headerLabel.trailingAnchor, constant: Russell.UI.sidePadding),
      
      detailLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Russell.UI.sidePadding),
      detailLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 5),
      container.trailingAnchor.constraint(equalTo: detailLabel.trailingAnchor, constant: Russell.UI.sidePadding),
      
      inputView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Russell.UI.sidePadding),
      inputView.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 20),
      container.trailingAnchor.constraint(equalTo: inputView.trailingAnchor, constant: Russell.UI.sidePadding),
      
      confirmButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Russell.UI.sidePadding),
      confirmButton.topAnchor.constraint(equalTo: inputView.bottomAnchor, constant: 20),
      confirmButton.heightAnchor.constraint(equalToConstant: 44),
      container.trailingAnchor.constraint(equalTo: confirmButton.trailingAnchor, constant: Russell.UI.sidePadding),
      container.bottomAnchor.constraint(equalTo: confirmButton.bottomAnchor, constant: 20)
      ])
  }
  
  @inline(__always)
  private func _buildHeaderLabel() -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = Russell.UI.theme.mediumFont.withSize(24)
    label.textColor = Russell.UI.theme.textColor.titleColor
    return label
  }
  
  @inline(__always)
  private func _buildDetailLabel() -> UITextView {
    let label = UITextView()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textContainer.lineFragmentPadding = 0
    label.textContainerInset.left = 0
    label.textContainerInset.right = 0
    label.isScrollEnabled = false
    label.isEditable = false
    label.backgroundColor = .white
    label.tintColor = Russell.UI.theme.tintColor
//    label.isSelectable = false
    label.delegate = self
    return label
  }
  
  @inline(__always)
  private func _buildInputView(initialDialCode: String) -> UIView {
    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    container.backgroundColor = Russell.UI.theme.input.backgroundColor
    container.layer.cornerRadius = Russell.UI.theme.input.radius
    container.layer.borderWidth = 1
    container.layer.borderColor = Russell.UI.theme.input.lineColor.cgColor
    
    let stack = UIStackView()
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.axis = .horizontal
    stack.alignment = .fill
    container.addSubview(stack)
    
    let areaCodeButton = AreaCodeButton()
    areaCodeButton.translatesAutoresizingMaskIntoConstraints = false
    areaCodeButton.updateContent(initialDialCode)
    areaCodeButton.addTarget(self, action: #selector(_selectAreaCode(_:)), for: .touchUpInside)
    self.areaCodeButton = areaCodeButton
    stack.addArrangedSubview(areaCodeButton)
    
    let verticalSpliter = UIView()
    verticalSpliter.translatesAutoresizingMaskIntoConstraints = false
    verticalSpliter.backgroundColor = Russell.UI.theme.input.lineColor
    stack.addArrangedSubview(verticalSpliter)
    
    let space = UIView()
    space.translatesAutoresizingMaskIntoConstraints = false
    stack.addArrangedSubview(space)
    
    let inputField = UITextField()
    self.mobileField = inputField
    inputField.delegate = self
    inputField.translatesAutoresizingMaskIntoConstraints = false
    inputField.clearButtonMode = .whileEditing
    inputField.font = Russell.UI.theme.input.font
    inputField.textColor = Russell.UI.theme.input.textColor
    inputField.placeholder = _UISafeLocalizedString(for: "Input-Mobile-Placeholder")
    inputField.keyboardType = .phonePad
    inputField.returnKeyType = .next
    inputField.textContentType = .telephoneNumber
    inputField.enablesReturnKeyAutomatically = true
    inputField.addTarget(self, action: #selector(_updateMobile(_:)), for: .editingChanged)
    inputField.addTarget(self, action: #selector(_next(_:)), for: .editingDidEndOnExit)
    stack.addArrangedSubview(inputField)
    
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
      stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 0),
      container.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: 0),
      container.bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: 0),
      
      areaCodeButton.widthAnchor.constraint(equalToConstant: 88),
      verticalSpliter.widthAnchor.constraint(equalToConstant: 1),
      
      space.widthAnchor.constraint(equalToConstant: 10),
      
      container.heightAnchor.constraint(equalToConstant: 48)
      ])
    
    return container
  }
  
  @inline(__always)
  private func _buildConfirmButton() -> UIButton {
    let button = BackgroundHighlightButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(_UISafeLocalizedString(for: "Input-Mobile-Button-Next"), for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.layer.cornerRadius = Russell.UI.theme.button.radius
    button.backgroundColor = Russell.UI.theme.tintColor
    button.defaultBackgroundColor = Russell.UI.theme.tintColor
    button.highlightedBackgroundColor = Russell.UI.theme.tintColor
    button.disabledBackgroundColor = UIColor(displayP3Red: 216 / 255, green: 216 / 255, blue: 216 / 255, alpha: 1)
    button.titleLabel?.font = Russell.UI.theme.button.font
    button.addTarget(self, action: #selector(_next(_:)), for: .touchUpInside)
    button.isEnabled = false
    return button
  }
}

// MARK: - Area Code Button

private final class AreaCodeButton: UIControl {
  
  func updateContent(_ content: String, animated: Bool = false) {
    guard animated else {
      return label.text = content
    }
    
    UIView.animate(withDuration: 0.25) {
      self.label.text = content
      self.layoutIfNeeded()
    }
  }
  
  func setIsOn(_ isOn: Bool, animated: Bool) {
    let transform = isOn ? CGAffineTransform.init(rotationAngle: .pi) : CGAffineTransform.identity
    guard animated else {
      return arrow.transform = transform
    }
    
    UIView.animate(withDuration: 0.25) {
      self.arrow.transform = transform
    }
  }
  
  override func willMove(toSuperview newSuperview: UIView?) {
    super.willMove(toSuperview: newSuperview)
    guard newSuperview != nil else { return }
    _setup()
  }
  
  private func _setup() {
    let stack = UIStackView()
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.axis = .horizontal
    stack.alignment = .center
    stack.isUserInteractionEnabled = false
    addSubview(stack)
    
    stack.addArrangedSubview(label)
    arrow.translatesAutoresizingMaskIntoConstraints = false
    stack.addArrangedSubview(arrow)
    
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 0),
      stack.topAnchor.constraint(equalTo: topAnchor, constant: 0),
      stack.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0),
      trailingAnchor.constraint(greaterThanOrEqualTo: stack.trailingAnchor, constant: 0),
      bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: 0)
      ])
  }
  
  private let label: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = Russell.UI.theme.mediumFont.withSize(18)
    label.textColor = Russell.UI.theme.input.textColor
    return label
  }()
  
  private let arrow = UIImageView(image: UIImage(named: "ic-choose", in: Bundle(for: AreaCodeButton.self), compatibleWith: nil))
}
