//
//  HUDViewController.swift
//  RussellUIForDemo
//
//  Created by Yunfan Cui on 2018/12/29.
//  Copyright © 2018 LLS. All rights reserved.
//

import UIKit

final class HUDViewController: UIViewController {
  
  private let messageWindow = UIView()
  
  private let stack = UIStackView()
  private let messageLabel = UILabel()
  private let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
  private let resultMarkLabel = UILabel()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
    
    messageWindow.translatesAutoresizingMaskIntoConstraints = false
    messageWindow.backgroundColor = .white
    view.addSubview(messageWindow)
    
    stack.axis = .vertical
    stack.spacing = 5
    stack.alignment = .center
    stack.translatesAutoresizingMaskIntoConstraints = false
    messageWindow.addSubview(stack)
    
    resultMarkLabel.translatesAutoresizingMaskIntoConstraints = false
    stack.addArrangedSubview(resultMarkLabel)
    
    activityIndicator.color = .darkGray
    activityIndicator.hidesWhenStopped = true
    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    stack.addArrangedSubview(activityIndicator)
    
    messageLabel.textColor = .black
    messageLabel.translatesAutoresizingMaskIntoConstraints = false
    messageLabel.numberOfLines = 0
    stack.addArrangedSubview(messageLabel)
    
    NSLayoutConstraint.activate([
      messageWindow.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      messageWindow.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      messageWindow.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
      view.trailingAnchor.constraint(greaterThanOrEqualTo: messageWindow.trailingAnchor, constant: 20),
      
      stack.leadingAnchor.constraint(equalTo: messageWindow.leadingAnchor, constant: 15),
      stack.topAnchor.constraint(equalTo: messageWindow.topAnchor, constant: 15),
      messageWindow.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: 15),
      messageWindow.bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: 15)
      ])
  }
  
  func setup(message: String) {
    messageLabel.text = message
    activityIndicator.stopAnimating()
    activityIndicator.isHidden = true
    resultMarkLabel.isHidden = true
  }
  
  func setupResult(isCorrect: Bool, message: String) {
    messageLabel.text = message
    
    activityIndicator.stopAnimating()
    activityIndicator.isHidden = true
    resultMarkLabel.text = isCorrect ? "✅" : "❌"
    resultMarkLabel.isHidden = false
  }
  
  func setupBusy(message: String) {
    messageLabel.text = message
    
    activityIndicator.startAnimating()
    activityIndicator.isHidden = false
    resultMarkLabel.isHidden = true
  }
}

final class HUD {
  
  private static let controller = HUDViewController()
  
  static func show(in vc: UIViewController) {
    
    update {
      controller.setupBusy(message: "Loading")
      vc.present(controller, animated: false, completion: nil)
    }
  }
  
  static func showError(message: String, in vc: UIViewController) {
    update {
      controller.setupResult(isCorrect: false, message: message)
      vc.present(controller, animated: false, completion: nil)
      DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
        controller.dismiss(animated: false, completion: nil)
      })
    }
  }
  
  static func showSuccess(message: String, in vc: UIViewController) {
    update {
      controller.setupResult(isCorrect: true, message: message)
      vc.present(controller, animated: false, completion: nil)
      DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
        controller.dismiss(animated: false, completion: nil)
      })
    }
  }
  
  static func dismiss() {
    update {}
  }
  
  private static func update(_ block: @escaping () -> Void) {
    controller.modalPresentationStyle = .custom
    controller.modalTransitionStyle = .crossDissolve
    
    if controller.presentingViewController != nil {
      controller.dismiss(animated: false, completion: block)
    } else {
      block()
    }
  }
}
