//
//  RussellUIConfiguration.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/7/22.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

public extension Russell.UI {
  
  struct Theme {
    /// Global regular font
    public var font = UIFont.systemFont(ofSize: 16)
    /// Global semibold font
    public var semiBoldFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
    /// Global medium font
    public var mediumFont = UIFont.systemFont(ofSize: 16, weight: .medium)
    /// Theme color
    public var tintColor = UIColor.orange
    /// Text colors
    public var textColor = TextColor()
    /// Input(Text Fields) customization
    public var input = Input()
    /// Button customization
    public var button = Button()
    
    public struct TextColor {
      public var titleColor = UIColor(displayP3Red: 33 / 255, green: 33 / 255, blue: 33 / 255, alpha: 1)
      public var contentColor = UIColor(displayP3Red: 117 / 255, green: 117 / 255, blue: 117 / 255, alpha: 1)
    }
    
    public struct Input {
      public var backgroundColor = UIColor.clear
      public var radius: CGFloat = 4
      public var font = UIFont.systemFont(ofSize: 18)
      public var lineColor = UIColor(displayP3Red: 234 / 255, green: 234 / 255, blue: 234 / 255, alpha: 1)
      public var textColor = UIColor.black
    }
    
    public struct Button {
      public var radius: CGFloat = 7
      public var font = UIFont.systemFont(ofSize: 18, weight: .semibold)
      public var disabledTitleColor = UIColor(displayP3Red: 177 / 255, green: 177 / 255, blue: 177 / 255, alpha: 1)
      public var style = Style.default
      
      /// 按钮样式
      ///
      /// - `default`: 默认样式
      /// - allFill: 所有按钮都是实色填充背景
      public enum Style {
        case `default`
        case allFill
      }
    }
  }
  
  static var headsUpDisplay: HeadsUpDisplay?
  static var theme = Theme()
}

public protocol HeadsUpDisplay {
  func show()
  func dismiss()
  func show(_ message: String)
  func showInfo(_ message: String)
  func showSuccess(_ message: String)
  func showError(_ message: String)
}

protocol HeadsUpDisplayable {}
extension HeadsUpDisplayable {
  var headsUpDisplay: HeadsUpDisplay? {
    return Russell.UI.headsUpDisplay
  }
}

// MARK: - Internal

extension Russell.UI {
  
  static var sidePadding: CGFloat {
    return UI_USER_INTERFACE_IDIOM() == .pad ? 40 : 20
  }
}
