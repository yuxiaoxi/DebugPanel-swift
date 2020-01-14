//
//  LLSDebugBar.swift
//  DebugPanel
//
//  Created by zhuo yu on 2019/8/28.
//  Copyright © 2019 zhuo yu. All rights reserved.
//

import UIKit
import FLEX

let kDebugBarItemHeight: CGFloat = 35
let kBottomButtonHeight: CGFloat = 20
let kDebugBarWidth: CGFloat = 145
let debugpanelopenurlKey = "com.liulishuo.debugpanel.openurl.identify.key"
private var iphoneXBangHeight: CGFloat = 0.0

/// 操作类型标识
public enum OperationTypeIndentify: String {
  case oneKeyProduct = "onekeyproductidentify"
  case oneKeyStaging = "onekeystagingidentify"
  case oneKeyDev = "onekeydevidentify"
  case routerURL = "routerurlidentify"
  case openDebugPanel = "opendebugpanelidentify"
}

/// 扩展button的样式类型
public enum DebugBarButtonStyle: Int {
  case ROWHASONE = 1 // 一行有只有一个button
  case ROWHASTWO = 2 // 一行有两个button
}

/// DebugPanel main class
public class LLSDebugBar: UIWindow {
  
  var contentView: UIView
  var bottomButton: UIButton
  var dismissButton: UIButton
  var urlWindow: UIView?
  var locationController: UINavigationController?
  var shakeReportButton: UIButton?
  public var debugDelegate: LLSDebugProtocol?
  var contentY: CGFloat
  var completionMap = [String: () -> Void]()
  var switchCompletionMap = [String: (Bool) -> Void]()
  var operationByParaMap = [String: (String) -> Void]()
  var naviPreView: LLSNaviPreView?
  var openURLStr: String?
  var inputURLView: UITextView?
  var iFlexShow: Bool = false
  var needAddHeight: Bool = true
  let performanceView: PerformanceMonitor = PerformanceMonitor()
  
  static var debugBar: LLSDebugBar?
  
  /// 启动debugpanel方法
  /// - Parameter start: 启动参数
  public static func  startDebugPanel(_ start: Bool) -> LLSDebugBar? {
    if start {
      if debugBar == nil {
        debugBar = LLSDebugBar(frame: CGRect(x: getDBScreenWidth()-kDebugBarWidth - 16, y: -20, width: kDebugBarWidth, height: 0))
      }
    } else {
      if debugBar != nil {
        debugBar = nil
      }
    }
    return debugBar
  }
  
  override init(frame: CGRect) {
    iphoneXBangHeight = 40.0
    contentView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    bottomButton = UIButton(type: .custom)
    dismissButton = UIButton(type: .custom)
    contentY = 0
    
    super.init(frame: frame)
    setup()
    configDefaultView()
    self.performanceView.performanceViewConfigurator.options = [.performance, .memory, .application]
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func setup() -> Void {
    self.windowLevel = UIWindow.Level.statusBar + 1.0
    self.backgroundColor = UIColor.clear
    self.isHidden = false
    self.rootViewController = UIViewController()
    UIApplication.shared.keyWindow?.makeKeyAndVisible()
  }
  
  @objc func actionFromCompletion(sender: UIButton) {
    let title = sender.title(for: .normal) ?? ""
    let completion: () -> Void = completionMap[title] ?? {}
    completion()
    self.perform(#selector(taggleClose), with: nil, afterDelay: 0.3)
  }
  
  @objc func alphaBottomButton() -> Void {
    UIView.animate(withDuration: 0.3, animations: {
      self.bottomButton.alpha = 1
    })
  }
  
  @objc func extensionSwitchChanged(sender: UISwitch) -> Void {
    let title = String(sender.tag)
    let completion: (Bool) -> Void = switchCompletionMap[title] ?? { _ in}
    completion(sender.isOn)
  }
  
  //reset button state
  @objc func switchValueChange(sender: UISwitch) -> Void {
    if sender.isOn {
      if self.performanceView.iStarted() {
        self.performanceView.show()
      } else {
        self.performanceView.start()
      }
    } else {
      self.performanceView.hide()
    }
    self.taggleClose()
  }
  
  @objc func taggleOpenClose() -> Void {
    if self.frame.maxY > 20 + iphoneXBangHeight {
      // 关上
      taggleClose()
    } else {
      // 打开
      taggleOpen()
    }
  }
  
  @objc func taggleOpen() -> Void {
    if self.frame.maxY <= 20 + iphoneXBangHeight {
      // 打开
      contentView.isHidden = false
      NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(alphaBottomButton), object: nil)
      NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(taggleClose), object: nil)
      UIView.animate(withDuration: 0.4, animations: {
        UIView.setAnimationCurve(.easeIn)
        var frame: CGRect = self.frame
        frame.origin.y = iphoneXBangHeight
        self.frame = frame
        self.bottomButton.alpha = 0
      })
    }
  }
  
  @objc func taggleClose() -> Void {
    if self.frame.maxY > 20 + iphoneXBangHeight {
      // 关上
      NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(alphaBottomButton), object: nil)
      NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(taggleClose), object: nil)
      UIView.animate(withDuration: 0.4, animations: {
        UIView.setAnimationCurve(.easeOut)
        var frame: CGRect = self.frame
        frame.origin.y = iphoneXBangHeight - self.contentY
        self.frame = frame
      }) { (finished: Bool) in
        self.perform(#selector(self.alphaBottomButton), with: nil, afterDelay: 0.3)
        UIApplication.shared.keyWindow?.makeKeyAndVisible()
        self.contentView.isHidden = true
      }
    }
  }
  
  //点击 flex 按钮事件
  @objc func toggleFlex(button: UIButton) -> Void {
    //打开flex功能
    if !iFlexShow {
      self.showFlexPanel()
    } else {
      self.hideFlexPanel()
    }
    iFlexShow = !iFlexShow
    let emojIcon = iFlexShow ? "🌞":"🌚"
    button.setTitle("FLEX\(emojIcon)", for: .normal)
    self.perform(#selector(taggleClose), with: nil, afterDelay: 0.3)
  }
  
  func showFlexPanel() {
    FLEXManager.shared().showExplorer()
  }
  
  func hideFlexPanel() {
    FLEXManager.shared().hideExplorer()
  }
  
  //点击打开面板跳转至面板页面
  @objc func showDebugPanel() {
    let completion: (() -> Void)? = completionMap[OperationTypeIndentify.openDebugPanel.rawValue]
    //两种注册方式：
    //1、通过回调方法
    //2、通过delegate
    if completion != nil {
      completion!()
    }else {
      self.debugDelegate?.openDebugPanel()
    }
    
    self.perform(#selector(taggleClose), with: nil, afterDelay: 0.3)
  }
  
  //点击一键切换 product 按钮
  @objc func changeProductServer() -> Void {
    //两种注册方式：
    //1、通过回调方法
    //2、通过delegate
    let completion: (() -> Void)? = completionMap[OperationTypeIndentify.oneKeyProduct.rawValue]
    if completion != nil {
      completion!()
    } else {
      self.debugDelegate?.oneKeyProduct()
    }
    
    self.perform(#selector(taggleClose), with: nil, afterDelay: 0.3)
  }
  
  //点击一键切换 staging 按钮
  @objc func changeStagingServer() -> Void {
    //两种注册方式：
    //1、通过回调方法
    //2、通过delegate
    let completion: (() -> Void)? = completionMap[OperationTypeIndentify.oneKeyStaging.rawValue]
    if completion != nil {
      completion!()
    } else {
      self.debugDelegate?.oneKeyStaging()
    }
    
    self.perform(#selector(taggleClose), with: nil, afterDelay: 0.3)
  }
  
  //点击一键切换 product 按钮
  @objc func changeDevServer() -> Void {
    //两种注册方式：
    //1、通过回调方法
    //2、通过delegate
    let completion: (() -> Void)? = completionMap[OperationTypeIndentify.oneKeyDev.rawValue]
    if completion != nil {
      completion!()
    } else {
      self.debugDelegate?.oneKeyDev()
    }
    
    self.perform(#selector(taggleClose), with: nil, afterDelay: 0.3)
  }
  
  //点击打开 url 按钮
  @objc func openURLWindow() -> Void {
    guard urlWindow == nil else {
      self.taggleClose()
      return
    }
  
    urlWindow = UIView(frame: UIScreen.main.bounds)
    urlWindow!.backgroundColor = UIColor(white: 1, alpha: 0.5)
    inputURLView = UITextView(frame: CGRect(x: 5, y: 45, width: 310, height: 90))
    inputURLView!.tag = 1
    inputURLView!.layer.borderColor = UIColor.lightGray.cgColor
    inputURLView!.layer.borderWidth = 1
    inputURLView!.layer.cornerRadius = 10
    let defaultUrlStr = UserDefaults.standard.string(forKey: debugpanelopenurlKey)
    let debugGoToUrl: String = defaultUrlStr != nil ? defaultUrlStr!: "lls://"
    inputURLView!.text = debugGoToUrl
    inputURLView!.accessibilityIdentifier = "debugtextview"
    urlWindow!.addSubview(inputURLView!)
    let cancelButton: UIButton = UIButton(type: .custom)
    cancelButton.setTitle("取消", for: .normal)
    cancelButton.backgroundColor = UIColor.colorWithHexString("#999999")
    cancelButton.setTitleColor(UIColor.white, for: .normal)
    cancelButton.layer.cornerRadius = 5
    cancelButton.frame = CGRect(x: 5, y: 140, width: 100, height: 40)
    cancelButton.addTarget(self, action: #selector(closeURLWindow), for: .touchUpInside)
    cancelButton.accessibilityIdentifier = "debugtextviewcancel"
    urlWindow!.addSubview(cancelButton)
    let goButton: UIButton = UIButton(type: .custom)
    goButton.setTitle("确定", for: .normal)
    goButton.backgroundColor = UIColor.colorWithHexString("#ff6633")
    goButton.setTitleColor(UIColor.white, for: .normal)
    goButton.layer.cornerRadius = 5
    goButton.frame = CGRect(x: 110, y: 140, width: 315-110, height: 40)
    goButton.addTarget(self, action: #selector(openURL), for: .touchUpInside)
    goButton.accessibilityIdentifier = "debugtextviewdone"
    urlWindow!.addSubview(goButton)
    UIApplication.shared.keyWindow?.addSubview(urlWindow!)
    inputURLView!.becomeFirstResponder()
    let tapRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeURLWindow))
    tapRecognizer.numberOfTapsRequired = 1
    urlWindow!.addGestureRecognizer(tapRecognizer)
    self.taggleClose()
  }
  
  @objc func closeURLWindow() -> Void {
    urlWindow?.removeFromSuperview()
    urlWindow = nil
  }
  
  //路由跳转
  @objc func openURL() -> Void {
    let completion: ((String) -> Void)? = operationByParaMap[OperationTypeIndentify.routerURL.rawValue]
    let urlStr = inputURLView?.text
    guard urlStr != nil else {
      self.closeURLWindow()
      return
    }
    
    UserDefaults.standard.set(urlStr, forKey: debugpanelopenurlKey)
    //两种注册方式：
    //1、通过回调方法
    //2、通过delegate
    if completion != nil {
      completion!(urlStr!)
    } else {
      self.debugDelegate?.openURLByRouter(urlStr!)
    }
    self.closeURLWindow()
  }
  
  //点击打开预览按钮
  @objc func openPreviewWindow() -> Void {
    guard naviPreView == nil else {
      self.taggleClose()
      return
    }
    
    naviPreView = LLSNaviPreView(frame: UIScreen.main.bounds)
    naviPreView?.delegate = self
    UIApplication.shared.keyWindow?.addSubview(naviPreView!)
    
    self.taggleClose()
  }
  
  func closePreViewWindow() -> Void {
    naviPreView?.removeFromSuperview()
    naviPreView = nil
  }
  
}

// MARK: Config View
extension LLSDebugBar {
  
  func configDefaultView() -> Void {
    contentView.backgroundColor = UIColor.white
    contentView.layer.borderColor = UIColor.lightGray.cgColor
    contentView.layer.borderWidth = 1
    contentView.layer.cornerRadius = 10
    self.addSubview(contentView)
    
    contentY = 5
    self.addButton(title: "打开调试面板", action: #selector(showDebugPanel), frame: CGRect(x: 5, y: contentY, width: 135, height: 30))
    contentY += kDebugBarItemHeight
    self.addButton(title: "一键Product", action: #selector(changeProductServer), frame: CGRect(x: 5, y: contentY, width: 65, height: 30))
    self.addButton(title: "一键Staging", action: #selector(changeStagingServer), frame: CGRect(x: 75, y: contentY, width: 65, height: 30))
    contentY += kDebugBarItemHeight
    
    self.addButton(title: "一键Dev", action: #selector(changeDevServer), frame: CGRect(x: 5, y: contentY, width: 135, height: 30))
    contentY += kDebugBarItemHeight
    
    self.addButton(title: "FLEX🌚", action: #selector(toggleFlex(button:)), frame: CGRect(x: 5, y: contentY, width: 135, height: 30))
    contentY += kDebugBarItemHeight
//    self.addButton(title: "打开URL", action: #selector(openURLWindow), frame: CGRect(x: 5, y: contentY, width: 135, height: 30))
//    contentY += kDebugBarItemHeight
    self.addButton(title: "预览所有页面", action: #selector(openPreviewWindow), frame: CGRect(x: 5, y: contentY, width: 135, height: 30))
    contentY += kDebugBarItemHeight
    configPerformanceWindow()
    configDismissButton()
    contentY += kDebugBarItemHeight
    
    self.frame = CGRect(x: getDBScreenWidth()-kDebugBarWidth - 16, y: iphoneXBangHeight - contentY, width: kDebugBarWidth, height: contentY+kBottomButtonHeight)
    contentView.frame = CGRect(x: 0, y: 0, width: kDebugBarWidth, height: contentY)
    contentView.isHidden = true
    configBottomButton()
  }
  
  func configPerformanceWindow() {
    let pfwLabel: UILabel = UILabel()
    pfwLabel.frame = CGRect(x: 5, y: contentY, width: 75, height: 30)
    pfwLabel.text = "性能悬浮圏"
    pfwLabel.backgroundColor = UIColor.groupTableViewBackground
    pfwLabel.font = UIFont.systemFont(ofSize: 10)
    pfwLabel.textColor = UIColor.black
    pfwLabel.textAlignment = .center
    contentView.addSubview(pfwLabel)
    let pfwSwitch: UISwitch = UISwitch()
    pfwSwitch.frame = CGRect(x: 85, y: contentY, width: 45, height: 20)
    pfwSwitch.setOn(false, animated: false)
    pfwSwitch.addTarget(self, action: #selector(switchValueChange(sender:)), for: .valueChanged)
    contentView.addSubview(pfwSwitch)
    contentY += kDebugBarItemHeight
  }
  
  func configBottomButton() {
    bottomButton.backgroundColor = UIColor.clear
    bottomButton.frame = CGRect(x: kDebugBarWidth - 80, y: contentY, width: kBottomButtonHeight, height: kBottomButtonHeight)
    bottomButton.setTitleColor(UIColor.orange, for: .normal)
    bottomButton.titleLabel!.font = UIFont.systemFont(ofSize: 12)
    bottomButton.setTitle("🐞", for: .normal)
    bottomButton.accessibilityIdentifier = "debug_button"
    bottomButton.addTarget(self, action: #selector(taggleOpenClose), for: .touchUpInside)
    self.addSubview(bottomButton)
  }
  
  func configDismissButton() {
    dismissButton.frame = CGRect(x: 5, y: contentY, width: 135, height: 30)
    dismissButton.backgroundColor = UIColor.groupTableViewBackground
    dismissButton.setTitleColor(UIColor.black, for: .normal)
    dismissButton.titleLabel!.font = UIFont.systemFont(ofSize: 10)
    dismissButton.setTitle("隐藏DebugBar", for: .normal)
    dismissButton.addTarget(self, action: #selector(taggleClose), for: .touchUpInside)
    contentView.addSubview(dismissButton)
  }
  
  func addButton(title: String, action: Selector, frame: CGRect) -> Void {
    let button: UIButton = UIButton(type: .roundedRect)
    button.frame = frame
    button.backgroundColor = UIColor.groupTableViewBackground
    button.setTitleColor(UIColor.black, for: .normal)
    button.titleLabel!.font = UIFont.systemFont(ofSize: 10)
    button.setTitle(title, for: .normal)
    button.addTarget(self, action: action, for: .touchUpInside)
    contentView.addSubview(button)
  }
  
}

// MARK: Public Methods
public extension LLSDebugBar {
  
  /// 添加扩展按钮方法
  /// - Parameter title: button的名字
  /// - Parameter buttonStyle: button样式，即：一行一个button或者一行两个button
  /// - Parameter completion: 是否需要增加高度，如果一行添加两个button，那第二个按钮不需要添加高度
  /// 注意：title名字不要重复，如果重复会影响点击事件
  func addExtentsionButton(_ title: String, buttonStyle: DebugBarButtonStyle , completion: @escaping () -> Void = {}) {
    guard !(title.count == 0) else {
      return
    }
    
    self.completionMap[title] = completion
    contentY = contentY - kDebugBarItemHeight
    if buttonStyle == DebugBarButtonStyle.ROWHASTWO {
      if needAddHeight {
        self.addButton(title: title, action: #selector(actionFromCompletion(sender:)), frame: CGRect(x: 5, y: contentY, width: 65, height: 30))
        contentY += kDebugBarItemHeight
        needAddHeight = false // 后面添加按钮不需要增加高度
      } else {
        self.addButton(title: title, action: #selector(actionFromCompletion(sender:)), frame: CGRect(x: 75, y: contentY - kDebugBarItemHeight, width: 65, height: 30))
        needAddHeight = true // 后面添加按钮需要增加高度
      }
    } else {
      self.addButton(title: title, action: #selector(actionFromCompletion(sender:)), frame: CGRect(x: 5, y: contentY, width: 135, height: 30))
      contentY += kDebugBarItemHeight // 总是需要增加高度
      needAddHeight = true
    }
    
    dismissButton.frame.origin.y = contentY
    contentY = contentY + kDebugBarItemHeight
    self.frame = CGRect(x: getDBScreenWidth()-kDebugBarWidth - 16, y: iphoneXBangHeight - contentY, width: kDebugBarWidth, height: contentY+kBottomButtonHeight)
    contentView.frame = CGRect(x: 0, y: 0, width: kDebugBarWidth, height: contentY)
    bottomButton.frame.origin.y = contentY
  }
  
  func addExtensionSwitch(_ title: String, _ defaultValue: Bool, completion: @escaping (Bool) -> Void = { _ in}) {
    guard !(title.count == 0) else {
      return
    }
    
    self.switchCompletionMap[String(title.hashValue)] = completion
    contentY = contentY - kDebugBarItemHeight
    let pfwLabel: UILabel = UILabel()
    pfwLabel.frame = CGRect(x: 5, y: contentY, width: 75, height: 30)
    pfwLabel.text = title
    pfwLabel.backgroundColor = UIColor.groupTableViewBackground
    pfwLabel.font = UIFont.systemFont(ofSize: 10)
    pfwLabel.textColor = UIColor.black
    pfwLabel.textAlignment = .center
    contentView.addSubview(pfwLabel)
    let pfwSwitch: UISwitch = UISwitch()
    pfwSwitch.frame = CGRect(x: 85, y: contentY, width: 45, height: 20)
    pfwSwitch.setOn(defaultValue, animated: false)
    pfwSwitch.tag = title.hashValue
    pfwSwitch.addTarget(self, action: #selector(extensionSwitchChanged(sender:)), for: .valueChanged)
    contentView.addSubview(pfwSwitch)
    contentY += kDebugBarItemHeight

    dismissButton.frame.origin.y = contentY
    contentY += kDebugBarItemHeight
    self.frame = CGRect(x: getDBScreenWidth()-kDebugBarWidth - 16, y: iphoneXBangHeight - contentY, width: kDebugBarWidth, height: contentY + kBottomButtonHeight)
    contentView.frame = CGRect(x: 0, y: 0, width: kDebugBarWidth, height: contentY)
    bottomButton.frame.origin.y = contentY
    
  }
  
  /// 设置常用按钮的点击事件
  /// - Parameter type: 操作类型
  /// - Parameter operation: 回调
  func configCommonOperattion(_ type: OperationTypeIndentify, operation: @escaping () -> Void = {}) {
    self.completionMap[type.rawValue] = operation
  }
  
  /// 设置路由跳转
  /// - Parameter type: 操作类型
  /// - Parameter openURL: 回调
  func openURLByRouter(_ type: OperationTypeIndentify, openURL: @escaping (String) -> Void = {_ in }) {
    self.operationByParaMap[type.rawValue] = openURL
  }

}

// MARK: LLSNaviPreViewProtocol
extension LLSDebugBar: LLSNaviPreViewProtocol {
  
  func naviPreViewNeedClose(preview: LLSNaviPreView) -> Void {
    self.closePreViewWindow()
  }
  
  func naviPreView(preview: LLSNaviPreView, shouldPopToViewController: UIViewController) -> Void {
    self.closePreViewWindow()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      let controller: UINavigationController? = UIApplication.shared.keyWindow?.rootViewController?.visibleNavigationViewController()
      controller?.popToViewController(shouldPopToViewController, animated: true)
    }
  }
  
}
