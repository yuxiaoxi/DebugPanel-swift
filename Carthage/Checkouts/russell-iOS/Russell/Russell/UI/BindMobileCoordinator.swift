//
//  BindMobileCoordinator.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/7/23.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit

public struct BindMobileConfiguration {
  public let privacyInfo: PrivacyInfo?
  let isRebinding: Bool
  let isExpired: Bool
  let requiresToken: Bool
  let session: String?
  /// 绑定手机页面提示消息
  var hintMessage: String?
  /// 是否允许取消
  var isCancellable = false
  /// 是否来自登录流程
  var isFromLogin = false
  /// 实名认证流程结束以后，是否自动关闭相关 UI
  var automaticallyDismissesRealNameUIAfterFinished = true
  
  /// 绑定手机选项
  ///
  /// - Parameters:
  ///   - privacyInfo: 用户是否同意过隐私协议，以及隐私协议跳转回调
  ///   - isRebinding: 用户是否已绑定手机。true 表示已绑定。
  ///   - isExpired: 已绑定手机是否过期
  ///   - requiresToken: 用户是否登录状态。true 表示登录状态
  ///   - session: 绑定手机 VERIFY_MOBILE Chanllenge session。外部调用传 nil。
  public init(privacyInfo: PrivacyInfo?, isRebinding: Bool, isExpired: Bool, requiresToken: Bool, session: String?) {
    self.privacyInfo = privacyInfo
    self.isRebinding = isRebinding
    self.isExpired = isExpired
    self.requiresToken = requiresToken
    self.session = session
  }
}

public extension RealNameInfo {
  
  var needsBinding: Bool {
    return !hasMobile || !isVerified || needRenew
  }
  
  func toBindingConfiguration(hasUserConfirmedPrivacyInfo: Bool) -> BindMobileConfiguration {
    return BindMobileConfiguration(
      privacyInfo: Russell.shared.map { PrivacyInfo(hasUserConfirmed: hasUserConfirmedPrivacyInfo, action: $0.privacyAction) },
      isRebinding: hasMobile,
      isExpired: !isVerified,
      requiresToken: requiresToken,
      session: session
    )
  }
}

protocol TextInputContainer: UIViewController {
  func beginTextEditing()
  func endTextEditing()
}

// MARK: - Coordinator

final class BindMobileCoordinator<Result: Decodable>: MobileInputDelegate, AreaCodePickerDelegate, VerifyMobileCodeDelegate, HeadsUpDisplayable {
  
  private weak var container: UINavigationController?
  private weak var inputController: MobileInputViewController?
  private weak var mobileCodeController: VerifyMobileCodeViewController?
  
  var completion: ((Result?, Error? ) -> Void)?
  
  private let worker: VerificationCodeFlowWorker<Result>
  private let configuration: BindMobileConfiguration
  private let tokenManage: _TokenManagerInternal
  init(worker: VerificationCodeFlowWorker<Result>, configuration: BindMobileConfiguration, tokenManager: _TokenManagerInternal) {
    self.worker = worker
    self.configuration = configuration
    self.tokenManage = tokenManager
  }
  
  deinit {
    self.headsUpDisplay?.dismiss()
  }
  
  // MARK: - Tracking
  
  var tracker: DataTracker?
  private var currentPageTracker: DataTracker? {
    return container.flatMap({ $0.topViewController as? _Trackable })?.tracker ?? tracker
  }
  
  // MARK: - Coordinating
  
  func launch(in container: Russell.UI.Container) {
    _setupWorker()
    
    let viewController = MobileInputViewController()
    viewController.delegate = self
    viewController.tracker = tracker
    
    viewController.setup(configuration: configuration, initialDialCode: selectedDialCode)
    
    inputController = viewController
    self.container = container.show(viewController: viewController)
  }
  
  func launch(in container: Russell.UI.Container, canBack: Bool) {
    _setupWorker()
    
    let viewController = MobileInputViewController()
    viewController.delegate = self
    viewController.tracker = tracker
    
    viewController.setup(configuration: configuration, initialDialCode: selectedDialCode)
    
    inputController = viewController
    self.container = container.show(viewController: viewController, canBack: canBack)
  }
  
  private func _setupWorker() {
    worker.callbacks.requiresVerificationCode = { [weak self] account, info, timeout in
      guard let self = self else { return }
      
      self.headsUpDisplay?.dismiss()
      self._showMobileVerification(account: account, info: info, timeout: timeout)
    }
    
    worker.callbacks.success = { [weak self] result in
      guard let self = self else { return }
      self.currentPageTracker?.action(actionName: "binding_success", properties: nil)
      self._complete(result: result)
    }
    
    worker.callbacks.failed = { [weak self] error in
      guard let self = self else { return }
      self._handleWorkerError(error)
    }
    
    if configuration.requiresToken, let token = Russell.currentAccessToken {
      worker.extraParameters = ["token": token]
      worker.extraHeaders = Network.headers(forToken: token)
    }
  }
  
  private func _showMobileVerification(account: String, info: MobileVerificationInfo?, timeout: Int) {
    if container?.topViewController is VerifyMobileCodeViewController {
      return _beginTextEditingOnCurrentScene()
    }
    
    func buildAndShow(targetStatus: TargetMobileStatusTracking?) {
      let viewController = VerifyMobileCodeViewController()
      viewController.initialTimeout = timeout
      viewController.delegate = self
      viewController.mobile = account
      viewController.tracker = targetStatus.flatMap({ tracker?.child(extraParameters: ["targetStatus": $0.rawValue]) }) ?? tracker
      mobileCodeController = viewController
      container?.pushViewController(viewController, animated: true)
    }
    
    guard let info = info else {
      return buildAndShow(targetStatus: nil)
    }
    
    // 打点参数
    let targetStatus: TargetMobileStatusTracking
    switch info.status {
    case .free:             targetStatus = .strong
    case .bound:            targetStatus = .weak
    case .oauthBoundable:   targetStatus = .oauthBoundable
    }
    
    if info.status == .bound {
      guard let container = container else { return }
      tracker?.action(actionName: "continue_to_verify", properties: nil)
      RealNameCertificationNotice.confirmWeakBinding.show(htmlMessage: info.message, in: container, confirmTrack: tracker?.lazyAction(name: "click_continue_to_verify_acknowledge", properties: nil)) {
        buildAndShow(targetStatus: targetStatus)
      }
    } else {
      buildAndShow(targetStatus: targetStatus)
    }
  }
  
  private func _complete(result: Result?, _ error: Error? = nil) {
    headsUpDisplay?.dismiss()
    if result != nil {
      headsUpDisplay?.showSuccess(_UISafeLocalizedString(for: "Successfully-Bound-Toast"))
    }
    
    guard let container = container else { return }
    
    if let auth = result as? Authentication {
      tokenManage.updateToken(auth.result.toToken())
    }
    let completion = { () -> Void in
      self.completion?(result, error)
    }
    
    if !configuration.automaticallyDismissesRealNameUIAfterFinished { // don't close binding UI after realname certification flow finished
      completion()
    } else if container.viewControllers.first == inputController { // presented, inputController is the root of navigation controller
      container.dismiss(animated: true, completion: completion)
    } else if container.viewControllers.first is OneKeyBinderViewController {
      container.dismiss(animated: true, completion: completion)
    } else if let index = container.viewControllers.firstIndex(where: { $0 === inputController }) { // pushed, 第一个页面不是手机号输入页
      CATransaction.begin()
      container.popToViewController(container.viewControllers[index - 1], animated: true)
      CATransaction.setCompletionBlock(completion)
      CATransaction.commit()
    } else { // should never be called
      completion()
    }
  }
  
  private func _handleWorkerError(_ error: Error) {
    // Track Worker Error
    let properties: [String: Any]? = Optional.some(error)
      .flatMap({ $0 as? RussellErrorCodeRepresentable })
      .flatMap({ $0.russellErrorCode })
      .map({ ["failed_reason": $0] })
    if container?.topViewController === inputController { // 当前是手机号输入页面
      currentPageTracker?.action(actionName: "process_failed", properties: properties)
    } else { // 当前是输入验证码页面
      currentPageTracker?.action(actionName: "binding_failed", properties: properties)
    }
    
    // Handle Error
    switch error {
    case RussellError.Binding.mobileAlreadyBound,
         RussellError.RealNameVerification.pleaseUseMobileToLogin:
      tracker?.action(actionName: "mobile_is_already_existed", properties: nil)
      headsUpDisplay?.dismiss()
      _warnAlreadyBound(error)
      
    case RussellError.RealNameVerification.sessionExpired:
      headsUpDisplay?.dismiss()
      _warnSessionExpired(error)
      
    case RussellError.RealNameVerification.weekBindExceeded:
      tracker?.action(actionName: "relationship_too_much_error", properties: nil)
      headsUpDisplay?.showError(error.localizedDescription)
      _beginTextEditingOnCurrentScene()
      
    default:
      headsUpDisplay?.showError(error.localizedDescription)
      _beginTextEditingOnCurrentScene()
    }
  }
  
  private func _warnAlreadyBound(_ error: Error) {
    guard let container = container else { return }
    
    tracker?.action(actionName: "getback_to_login", properties: nil)
    
    RealNameCertificationAlert.mobileAlreadyBound.show(
      in: container,
      confirmTrack: tracker?.lazyAction(name: "click_getback_to_login_existed_account", properties: nil),
      cancelTrack: tracker?.lazyAction(name: "click_getback_to_login_rebinding", properties: nil),
      cancelAction: {
        self.inputController?.clearMobile()
        self._beginTextEditingOnCurrentScene()
      },
      completion: { self._complete(result: nil, error) })
  }
  
  private func _warnSessionExpired(_ error: Error) {
    guard let container = container else { return }
    tracker?.action(actionName: "relogin_page_stay_too_long", properties: nil)
    RealNameCertificationNotice.sessionExpired.show(htmlMessage: nil, in: container, confirmTrack: tracker?.lazyAction(name: "click_relogin", properties: nil)) {
      self._complete(result: nil, error)
    }
  }
  
  // MARK: - Keyboard Control
  
  private func _beginTextEditingOnCurrentScene() {
    guard let container = self.container?.topViewController as? TextInputContainer else { return }
    container.beginTextEditing()
  }
  
  private func _endTextEditingOnCurrentScene() {
    guard let container = self.container?.topViewController as? TextInputContainer else { return }
    container.endTextEditing()
  }
  
  // MARK: - MobileInputDelegate
  
  func presentAreaCodePicker() {
    let controller = AreaCodePickerViewController(selectedDial: selectedDialCode)
    controller.delegate = self
    container?.present(controller, animated: true, completion: nil)
  }
  
  func isValidMobile(_ mobile: String) -> Bool {
    return MobileValidator.isValidMobile(dialCode: selectedDialCode, mobile: mobile)
  }
  
  func verify(mobile: String) {
    headsUpDisplay?.show()
    _endTextEditingOnCurrentScene()
    worker.sendVerificationCode(to: selectedDialCode + mobile)
  }
  
  func performExternalAction(_ action: @escaping (UINavigationController) -> Void) {
    guard let container = container else { return }
    action(container)
  }
  
  func cancelBinding() {
    _complete(result: nil)
  }
  
  // MARK: - AreaCodePickerDelegate
  
  func areaCodePickerDismissed() {
    inputController?.areaCodePickerDismissed()
  }
  
  func presentAreaCodeSearcher() {
    let controller = AreaCodeSearchViewController()
    controller.delegate = self
    container?.present(controller, animated: true, completion: nil)
  }
  
  func updateSelection(_ dialCode: String) {
    selectedDialCode = dialCode
    inputController?.updateSelection(dialCode)
  }
  
  // MARK: - VerifyMobileCodeDelegate
  
  func verify(code: String) {
    headsUpDisplay?.show()
    _endTextEditingOnCurrentScene()
    worker.verify(code: code)
  }
  
  func resendVerificationCode() {
    headsUpDisplay?.show()
    _endTextEditingOnCurrentScene()
    worker.resendVerificationCode()
  }
  
  func cancelMobileCodeInput() {
    container?.popViewController(animated: true)
  }
  
  // selectedDialCode
  
  private(set) lazy var selectedDialCode = self._loadDefaultDialCode()
  
  @inline(__always)
  private func _loadDefaultDialCode() -> String {
    let locale = Locale.current 
    if let matchedAreaCode = AreaCodeLoader.shared.areaCodes.first(where: { $0.countryCode == locale.regionCode }) {
      return matchedAreaCode.dialCode
    } else {
      return AreaCodeLoader.shared.areaCodes.first!.dialCode
    }
  }
}
