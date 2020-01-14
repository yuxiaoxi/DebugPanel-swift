//
//  NoticeAlert.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/7/24.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

// MARK: - Notice

protocol Notice: RawRepresentable where RawValue == String {}

extension Notice {
  
  func show(htmlMessage: String?, in container: UIViewController, confirmTrack: (() -> Void)?, completion: @escaping () -> Void) {
    show(attributedMessage: htmlMessage.map { $0.htmlAttributedMessage() }, in: container, confirmTrack: confirmTrack, completion: completion)
  }
  
  func show(attributedMessage: NSAttributedString?, in container: UIViewController, confirmTrack: (() -> Void)?, completion: @escaping () -> Void) {
    let title = _localizedString(prefix: "Notice-Title")
    let actionTitle = _safeLocalizedString(prefix: "Notice-Action")
    
    let action = AlertAction(title: actionTitle) {
      confirmTrack?()
      completion()
    }
    
    let alertController = AlertController(
      attributedTitle: title.map(NSAttributedString.init),
      attributedMessage: attributedMessage ?? _localizedString(prefix: "Notice-Message")?.attributedMessage(),
      confirmAction: action,
      cancelAction: nil
    )
    alertController.tintColor = Russell.UI.theme.tintColor
    container.present(alertController, animated: true, completion: nil)
  }
}

// MARK: - Alert

protocol Alert: RawRepresentable where RawValue == String {}

extension Alert {
  
  func show(htmlMessage: String?, in container: UIViewController, confirmTrack: (() -> Void)?, cancelTrack: (() -> Void)?, cancelAction: (() -> Void)? = nil, completion: @escaping () -> Void) {
    show(attributedMessage: htmlMessage.map { $0.htmlAttributedMessage() }, in: container, confirmTrack: confirmTrack, cancelTrack: cancelTrack, cancelAction: cancelAction, completion: completion)
  }
  
  func show(attributedMessage: NSAttributedString? = nil, in container: UIViewController, confirmTrack: (() -> Void)?, cancelTrack: (() -> Void)?, cancelAction: (() -> Void)? = nil, completion: @escaping () -> Void) {
    let title = _localizedString(prefix: "Alert-Title")
    let actionTitle = _safeLocalizedString(prefix: "Alert-Action")
    let cancelTitle = _safeLocalizedString(prefix: "Alert-Cancel")
    
    let confirmAction = AlertAction(title: actionTitle) {
      confirmTrack?()
      completion()
    }
    
    let cancelAction = AlertAction(title: cancelTitle) {
      cancelTrack?()
      cancelAction?()
    }
    
    let alertController = AlertController(
      attributedTitle: title.map(NSAttributedString.init),
      attributedMessage: attributedMessage ?? _localizedString(prefix: "Alert-Message")?.attributedMessage(),
      confirmAction: confirmAction,
      cancelAction: cancelAction
    )
    alertController.tintColor = Russell.UI.theme.tintColor
    container.present(alertController, animated: true, completion: nil)
  }
}

// MARK: -

private extension RawRepresentable where RawValue == String {
  func _safeLocalizedString(prefix: String) -> String {
    return _UISafeLocalizedString(for: _localizationKey(prefix: prefix))
  }
  
  func _localizedString(prefix: String) -> String? {
    return _UILocalizedString(for: _localizationKey(prefix: prefix))
  }
  
  private func _localizationKey(prefix: String) -> String {
    return "\(prefix)-\(type(of: self))-\(rawValue)"
  }
}

private extension String {
  
  func htmlAttributedMessage(fontSize: CGFloat = 14) -> NSAttributedString {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineHeightMultiple = 1.5
    
    guard let html = try? NSMutableAttributedString(
      data: data(using: .utf8)!,
      options: [.documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue,
                .defaultAttributes: [NSAttributedString.Key.font: Russell.UI.theme.font.withSize(fontSize), .paragraphStyle: paragraphStyle]],
      documentAttributes: nil)
      else { return NSAttributedString(string: self, attributes: [.paragraphStyle: paragraphStyle]) }
    
    var range = NSRange(location: 0, length: 0)
    while range.upperBound < html.length,
      let font = html.attributes(at: range.upperBound, effectiveRange: &range)[.font] as? UIFont,
      range.location != NSNotFound {
        
        let isBold = font.fontName.lowercased().contains("bold")
        html.setAttributes(
          [.font: isBold ? Russell.UI.theme.semiBoldFont.withSize(fontSize) : Russell.UI.theme.font.withSize(fontSize),
           .paragraphStyle: paragraphStyle],
          range: range)
    }
    
    return html
  }
  
  func attributedMessage(fontSize: CGFloat = 14) -> NSAttributedString {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineHeightMultiple = 1.5
    return NSAttributedString(string: self, attributes: [NSAttributedString.Key.font: Russell.UI.theme.font.withSize(fontSize), .paragraphStyle: paragraphStyle])
  }
}
