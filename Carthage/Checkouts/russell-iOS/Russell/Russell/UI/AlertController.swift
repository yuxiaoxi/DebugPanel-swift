//
//  AlertController.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/8/6.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit

struct AlertAction {
  let title: String
  let action: (() -> Void)?
}

final class AlertController: UIViewController {
  private let attributedTitle: NSAttributedString?
  private let attributedMessage: NSAttributedString?
  private let confirmAction: AlertAction
  private let cancelAction: AlertAction?
  
  required init(attributedTitle: NSAttributedString?, attributedMessage: NSAttributedString?, confirmAction: AlertAction, cancelAction: AlertAction?) {
    self.attributedTitle = attributedTitle
    self.attributedMessage = attributedMessage
    self.confirmAction = confirmAction
    self.cancelAction = cancelAction
    
    super.init(nibName: nil, bundle: nil)
    
    modalTransitionStyle = .crossDissolve
    modalPresentationStyle = .overFullScreen
  }
  
  convenience init(title: String?, message: String?, confirmAction: AlertAction, cancelAction: AlertAction?) {
    self.init(
      attributedTitle: title.map { NSAttributedString(string: $0, attributes: [.font: Russell.UI.theme.semiBoldFont.withSize(18)]) },
      attributedMessage: message.map { NSAttributedString(string: $0, attributes: [.font: Russell.UI.theme.font.withSize(14)]) },
      confirmAction: confirmAction,
      cancelAction: cancelAction)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Layout
  
  var tintColor: UIColor?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
    view.tintColor = tintColor
    buildContent()
  }
  
  private func buildContent() {
    
    // Blur Effect Container
    let blur = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    blur.translatesAutoresizingMaskIntoConstraints = false
    blur.layer.cornerRadius = 12
    blur.layer.masksToBounds = true
    view.addSubview(blur)
    let container = blur.contentView
    
    // Title & Message Container
    let contentContainer = UIView()
    contentContainer.translatesAutoresizingMaskIntoConstraints = false
    contentContainer.backgroundColor = .white
    container.addSubview(contentContainer)
    
    let contentStack = UIStackView()
    contentStack.translatesAutoresizingMaskIntoConstraints = false
    contentStack.axis = .vertical
    contentStack.alignment = .center
    contentStack.spacing = 5
    contentContainer.addSubview(contentStack)
    
    // Title & Message Label Builder
    func buildLabel(_ attributedText: NSAttributedString) -> UILabel {
      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      label.numberOfLines = 0
      label.textColor = Russell.UI.theme.textColor.titleColor
      label.attributedText = attributedText
      return label
    }
    attributedTitle.map(buildLabel).map(contentStack.addArrangedSubview)
    attributedMessage.map(buildLabel).map(contentStack.addArrangedSubview)
    
    // Horizontal Line
    func buildLine(isHorizontal: Bool) -> UIView {
      let line = UIView()
      line.translatesAutoresizingMaskIntoConstraints = false
      line.backgroundColor = UIColor(displayP3Red: 242 / 255, green: 242 / 255, blue: 242 / 255, alpha: 1)
      if isHorizontal {
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
      } else {
        line.widthAnchor.constraint(equalToConstant: 1).isActive = true
      }
      return line
    }
    let hLine = buildLine(isHorizontal: true)
    container.addSubview(hLine)
    
    // Button Container
    let buttonStack = UIStackView()
    buttonStack.translatesAutoresizingMaskIntoConstraints = false
    buttonStack.axis = .vertical
    container.addSubview(buttonStack)
    
    // Button Builder
    func buildButton(title: String, isBold: Bool, selector: Selector) -> UIButton {
      let button = BackgroundHighlightButton(type: .custom)
      button.translatesAutoresizingMaskIntoConstraints = false
      button.backgroundColor = .white
      button.defaultBackgroundColor = .white
      button.highlightedBackgroundColor = UIColor.white.withAlphaComponent(0.8)
      button.titleLabel?.font = isBold ? Russell.UI.theme.semiBoldFont.withSize(18) : Russell.UI.theme.font.withSize(18)
      button.setTitle(title, for: .normal)
      if isBold, let tintColor = view.tintColor {
        button.setTitleColor(tintColor, for: .normal)
        button.setTitleColor(tintColor, for: .highlighted)
      } else {
        button.setTitleColor(Russell.UI.theme.textColor.contentColor, for: .normal)
        button.setTitleColor(Russell.UI.theme.textColor.contentColor, for: .highlighted)
      }
      button.addTarget(self, action: selector, for: .touchUpInside)
      button.heightAnchor.constraint(equalToConstant: 55).isActive = true
      
      return button
    }
    
    let confirmButton = buildButton(title: confirmAction.title, isBold: true, selector: #selector(self.confirm))
    buttonStack.addArrangedSubview(confirmButton)
    if let cancelAction = cancelAction {
      let cancelButton = buildButton(title: cancelAction.title, isBold: false, selector: #selector(self.cancel))
      
      if cancelAction.title.count + confirmAction.title.count < 10 {
        buttonStack.axis = .horizontal
        buttonStack.insertArrangedSubview(buildLine(isHorizontal: false), at: 0)
        buttonStack.insertArrangedSubview(cancelButton, at: 0)
      } else {
        buttonStack.addArrangedSubview(buildLine(isHorizontal: true))
        buttonStack.addArrangedSubview(cancelButton)
      }
      
      cancelButton.widthAnchor.constraint(equalTo: confirmButton.widthAnchor, multiplier: 1).isActive = true
    }
    
    // Constraints
    
    NSLayoutConstraint.activate([
      blur.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
      blur.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0),
      blur.widthAnchor.constraint(equalToConstant: 270),
      
      contentContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
      contentContainer.topAnchor.constraint(equalTo: container.topAnchor, constant: 0),
      container.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: 0),
      
      contentStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 20),
      contentStack.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 30),
      contentContainer.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor, constant: 20),
      contentContainer.bottomAnchor.constraint(equalTo: contentStack.bottomAnchor, constant: 30),
      
      hLine.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
      hLine.topAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: 0),
      container.trailingAnchor.constraint(equalTo: hLine.trailingAnchor, constant: 0),
      
      buttonStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
      buttonStack.topAnchor.constraint(equalTo: hLine.bottomAnchor, constant: 0),
      container.trailingAnchor.constraint(equalTo: buttonStack.trailingAnchor, constant: 0),
      container.bottomAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: 0)
      ])
  }
  
  @objc private func cancel() {
    dismiss(animated: true, completion: cancelAction?.action)
  }
  
  @objc private func confirm() {
    dismiss(animated: true, completion: confirmAction.action)
  }
}

final class BackgroundHighlightButton: UIButton {
  var defaultBackgroundColor: UIColor?
  var highlightedBackgroundColor: UIColor?
  var disabledBackgroundColor: UIColor?
  
  override var isHighlighted: Bool {
    get { return super.isHighlighted }
    set {
      backgroundColor = newValue ? highlightedBackgroundColor : defaultBackgroundColor
      super.isHighlighted = newValue
    }
  }
  
  override var isEnabled: Bool {
    get { return super.isEnabled }
    set {
      backgroundColor = newValue ? defaultBackgroundColor : disabledBackgroundColor
      super.isEnabled = newValue
    }
  }
}
