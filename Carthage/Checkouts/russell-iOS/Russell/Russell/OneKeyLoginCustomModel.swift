//
//  OnekeyLoginCustomModel.swift
//  Russell
//
//  Created by zhuo yu on 2019/10/15.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit

/// 按钮点击打点相关的 Key
enum ActionKeys: String {
  case loginButtonActionKey = "click_authorize_button"
  case changeButtonActionKey = "click_switch_hyperlink"
  case weiXinButtonActionKey = "click_wechat_button"
  case qqButtonActionKey = "click_qq_button"
  case weiBoButtonActionKey = "click_weibo_button"
  case emailButtonActionKey = "click_email_button"
}

/// 使用类型
/// OneKeyLogin： 一键登录
/// OneKeyBinder: 一键绑定
public enum UseType: Int {
  case OneKeyLogin = 0
  case OneKeyBinder = 1
}

/// 手机号一键登录模型配置类
final public class OneKeyLoginCustomModel: NSObject {
  
  private var onekeyLoginVC = UIViewController()
  
  /// 构造方法：使用 SDK 内置 Viewcontoller，只需要传入定制的 View
  /// - Parameter selfView: 一键登录授权页的 selfView
  /// - Parameter loginButton: 一键登录授权页的一键登录按钮
  /// - Parameter changeTypeButton: 一键登录授权页的切换其他登录方式按钮
  public init(selfView: UIView, loginButton: UIButton, changeTypeButton: UIButton?) {
    onekeyLoginVC.modalPresentationStyle = .fullScreen
    onekeyLoginVC.view = selfView
    onekeyLoginVC.modalPresentationStyle = .fullScreen
    // 配置一键登录按钮
    loginButton._addLayerUIView(.loginButtonActionKey)
    // 配置切换其他登录方式按钮
    changeTypeButton?._addLayerUIView(.changeButtonActionKey)
  }
  
  /// 配置一键登录按钮
  /// - Parameter loginButton: loginButton
  public static func configLoginButton(_ loginButton: UIButton, _ useType: UseType = .OneKeyLogin) {
    loginButton._addLayerUIView(.loginButtonActionKey, useType)
  }
  
  /// 配置切换其他登录方式按钮
  /// - Parameter loginButton: loginButton
  public static func configChangeButton(_ changeButton: UIButton, _ useType: UseType = .OneKeyLogin) {
    changeButton._addLayerUIView(.changeButtonActionKey, useType)
  }
  
  /// 一键登录授权 VC
  public var loginMainViewController: UIViewController {
    return onekeyLoginVC
  }
  
  /// 配置点击微信登录按钮，方便记录其他打点事件，可选配置
  /// - Parameter weiXinButton: weixin 按钮
  public func configWeiXinButton(_ weiXinButton: UIButton) {
    weiXinButton._addLayerUIView(.weiXinButtonActionKey)
  }
  
  /// 配置点击 QQ 登录按钮，方便记录其他打点事件，可选配置
  /// - Parameter qqButton: QQ 按钮
  public func configQQButton(_ qqButton: UIButton) {
    qqButton._addLayerUIView(.qqButtonActionKey)
  }
  
  /// 配置点击 微博 登录按钮，方便记录其他打点事件，可选配置
  /// - Parameter weiBoButton: 微博 按钮
  public func configWeiBoButton(_ weiBoButton: UIButton) {
    weiBoButton._addLayerUIView(.weiBoButtonActionKey)
  }
  
  /// 配置点击 邮箱 登录按钮，方便记录其他打点事件，可选配置
  /// - Parameter emailButton: 邮箱 按钮
  public func configEmailButton(_ emailButton: UIButton) {
    emailButton._addLayerUIView(.emailButtonActionKey)
  }
  
}

// MARK: button add layerview
extension UIButton {
  
  func _addLayerUIView(_ actionKey: ActionKeys, _ useType: UseType = .OneKeyLogin) {
    let layerFrame = CGRect(origin: CGPoint(x: 0, y: 0), size: self.frame.size)
    let layerView = LayerView.init(frame: layerFrame, actionKey: actionKey.rawValue, useType: useType)
    layerView.backgroundColor = UIColor.clear
    self.addSubview(layerView)
  }
  
}

// MARK: 自定义view
class LayerView: UIControl {
  
  private var actionKey: String = ""
  private var useType: UseType = .OneKeyLogin
  
  init(frame: CGRect, actionKey: String, useType: UseType) {
    super.init(frame: frame)
    self.actionKey = actionKey
    self.useType = useType
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    // 点击事件，打点
    OneKeyLogin.shared.tracker?.action(actionName: actionKey, pageCategory: "russell_sdk", pageName: "ali_authorization", properties: [
      "type": self.useType.rawValue
    ])
    // 调用父控件UIButton的点击事件方法
    if let superButton: UIButton = self.superview as? UIButton {
      superButton.sendActions(for: .touchUpInside)
    }
  }
  
}
