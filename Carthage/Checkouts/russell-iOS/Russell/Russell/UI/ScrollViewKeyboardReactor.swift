//
//  ScrollViewKeyboardReactor.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/8/28.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

final class ScrollViewKeyboardReactor {
  
  weak var scrollView: UIScrollView? {
    didSet {
      if scrollView == nil {
        unregisterKeyboardNotifications()
      } else {
        registerKeyboardNotifications()
      }
    }
  }
  
  private func registerKeyboardNotifications() {
    NotificationCenter.default.addObserver(self, selector: #selector(_keyboardWillShowUp(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(_keyboardWillShowUp(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(_keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
  }
  
  private func unregisterKeyboardNotifications() {
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc private func _keyboardWillShowUp(_ notification: Notification) {
    guard notification.name == UIResponder.keyboardWillChangeFrameNotification || notification.name == UIResponder.keyboardWillShowNotification,
      let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
      else { return }
    
    scrollView?.contentInset.bottom = endFrame.height
  }
  
  @objc private func _keyboardWillHide(_ notification: Notification) {
    guard notification.name == UIResponder.keyboardWillHideNotification else { return }
    scrollView?.contentInset.bottom = 0
  }
}

extension ScrollViewKeyboardReactor {
  
  static func buildContentScrollViewWithReactorInContainer(_ container: UIView) -> (reactor: ScrollViewKeyboardReactor, contentView: UIView) {
    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.keyboardDismissMode = .onDrag
    container.addSubview(scrollView)
    
    let contentView = UIView()
    contentView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(contentView)
    
    NSLayoutConstraint.activate([
      scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
      scrollView.topAnchor.constraint(equalTo: container.topAnchor, constant: 0),
      container.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: 0),
      container.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 0),
      scrollView.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 1),
      
      contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 0),
      contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 0),
      scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
      scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
      contentView.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 1)
      ])
    
    let reactor = ScrollViewKeyboardReactor()
    reactor.scrollView = scrollView
    
    return (reactor, scrollView)
  }
}
