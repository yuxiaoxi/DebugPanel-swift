//
//  RussellUI.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/7/22.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

// MARK: - Name Space

public extension Russell {
  enum UI {}
}

// MARK: - APIs

public extension Russell.UI {
  
  /// 展示已绑定手机。如果用户尚未绑定手机，则直接进入绑定流程
  ///
  /// - Parameter container: 容器
  static func showBoundMobile(in container: Container) {
    container.show(viewController: ReviewBoundMobileViewController())
  }
  
  /// 警告用户实名认证状态异常。
  ///
  /// - Parameters:
  ///   - container: 容器
  ///   - message: 需要将 RealNameInfo.message 透传。如果非 fetchRealNameInfo 触发，则传 nil
  ///   - showsWarningWhenExpired: 如果用户当前处于弱绑定已过期状态，是否先展示 alert 再跳转到绑定流程。默认为 false
  ///   - configuration: 绑定流程配置。一般通过 RealNameInfo.toBindingConfiguration(hasUserConfirmedPrivacyInfo:) 生成。
  ///   - completion: 绑定流程回调
  static func warnRealName(in container: Container, message: String?, showsWarningWhenExpired: Bool = false, configuration: BindMobileConfiguration, completion: @escaping (Error?) -> Void) {
    let tracker = Russell.shared?.dataTracker
    tracker?.action(actionName: "remind_expiration_warning", properties: nil)
    
    var tracking = BindMobileTracking(source: .expiration, currentMobileStatus: .none)
    var configuration = configuration
    
    let alertCompletion = {
      self._bindMobile(in: container, configuration: configuration, tracking: tracking, completion: completion)
    }
    
    if configuration.isRebinding, !configuration.isExpired {
      tracking.source = .expirationReminder
      tracking.currentMobileStatus = .weak
      configuration.isCancellable = true
      RealNameCertificationAlert.weakBoundExpiring.show(
        htmlMessage: message,
        in: container.alertContainer,
        confirmTrack: tracker?.lazyAction(name: "click_remind_expiration_warning_change_now", properties: nil),
        cancelTrack: tracker?.lazyAction(name: "click_remind_expiration_warning_change_later", properties: nil),
        cancelAction: { completion(RussellError.RealNameVerification.canceled) },
        completion: alertCompletion)
    } else if showsWarningWhenExpired, configuration.isExpired {
      if configuration.privacyInfo?.hasUserConfirmed != true {
        tracking.source = .bindingWithPolicy
      }
      RealNameCertificationNotice.bindMobile.show(
        htmlMessage: message,
        in: container.alertContainer,
        confirmTrack: tracker?.lazyAction(name: "click_remind_expiration_warning_change_now", properties: nil),
        completion: alertCompletion)
    } else {
      if configuration.privacyInfo?.hasUserConfirmed != true {
        tracking.source = .bindingWithPolicy
      }
      configuration.hintMessage = message
      alertCompletion()
    }
  }
  
  internal static func _bindMobile(in container: Container, configuration: BindMobileConfiguration, tracking: BindMobileTracking, completion: @escaping (Error?) -> Void) {
    guard let service = Russell.shared else { return completion(RussellError.Common.inappropriateUsage) }
    
    if let session = configuration.session, !session.isEmpty {
      let coordinator = BindMobileCoordinator(worker: service._mobileVerificationWorker(session: session), configuration: configuration, tokenManager: service.tokenManager)
      coordinator.tracker = service.dataTracker.child(extraParameters: tracking.parameters)
      coordinator.completion = { result, error in
        completion(result == nil ? RussellError.RealNameVerification.canceled: nil)
      }
      coordinator.launch(in: container)
    } else {
      let coordinator = BindMobileCoordinator(worker: service._bindMobileWorker(), configuration: configuration, tokenManager: service.tokenManager)
      coordinator.tracker = service.dataTracker.child(extraParameters: tracking.parameters)
      coordinator.completion = { result, error in
        completion(result == nil ? RussellError.RealNameVerification.canceled: nil)
      }
      coordinator.launch(in: container)
    }
  }
  
  internal static func _realNameCertificate(in container: Container, session: String, configuration: BindMobileConfiguration, tracking: BindMobileTracking, canBack: Bool? = false, completion: @escaping (Authentication?, Error?) -> Void) {
    guard let service = Russell.shared, let session = configuration.session else {
      return assertionFailure("Russell service not ready, or internal logic error")
    }
    
    let coordinator = BindMobileCoordinator(worker: service._mobileVerificationWorker(session: session), configuration: configuration, tokenManager: service.tokenManager)
    coordinator.tracker = service.dataTracker.child(extraParameters: tracking.parameters)
    coordinator.completion = completion
    coordinator.launch(in: container, canBack: canBack!)
  }
  
  internal static func _showOneKeyBinder(in container: Container, session: String, isSignup: Bool, delegate: OneKeyBinderSessionDelegate, binderBlock: @escaping(_ container: Russell.UI.Container, _ sessionID: String, _ isNewRegister: Bool, _ canBack: Bool, _ source: BindMobileTracking.Source) -> Void = { _, _, _, _, _ in }) {

    let vc = OneKeyBinderViewController(privacyInfo: Russell.OneKeyLoginFlow.privacyInfo!, sessionID: session, isSignup: isSignup, delegate: delegate, binderBlock: binderBlock)!
    OneKeyLoginCustomModel.configLoginButton(vc.onekeyLoginButton, .OneKeyBinder)
    OneKeyLoginCustomModel.configChangeButton(vc.changeButton, .OneKeyBinder)
    Russell.OneKeyLoginFlow.startWakeAuthorizationViewController(useType: .OneKeyBinder) {
      container.show(viewController: vc)
    }
  }
}

// MARK: - Container

public extension Russell.UI {
  
  enum Container {
    case presentation(UIViewController)
    case navigation(UINavigationController)
    
    @discardableResult func show(viewController: UIViewController) -> UINavigationController {
      switch self {
      case .navigation(let navigationController):
        navigationController.pushViewController(viewController, animated: true)
        return navigationController
      case .presentation(let presenter):
        let navigationController = _navigationController(root: viewController)
        presenter.present(navigationController, animated: true, completion: nil)
        return navigationController
      }
    }
    
    @discardableResult func show(viewController: UIViewController, canBack: Bool) -> UINavigationController {
      switch self {
      case .navigation(let navigationController):
        navigationController.pushViewController(viewController, animated: true)
        return navigationController
      case .presentation(let presenter):
        if canBack {
          presenter.navigationController?.pushViewController(viewController, animated: true)
          return presenter.navigationController!
        } else {
          if presenter is OneKeyBinderViewController {
            /// 如果是从一键绑定页跳转至默认绑定页且不能返回时需要关闭一键绑定页
            let navigationController = presenter.navigationController
            navigationController?.setViewControllers([viewController], animated: true)
            return navigationController!
          } else {
            return show(viewController: viewController)
          }
        }
      }
    }
    
    var alertContainer: UIViewController {
      switch self {
      case .navigation(let controller): return controller
      case .presentation(let controller): return controller
      }
    }
    
    private func _navigationController(root: UIViewController) -> UINavigationController {
      let navigationController = UINavigationController(rootViewController: root)
      navigationController.modalPresentationStyle = .fullScreen
      
      let image = _createImage(size: CGSize(width: 1, height: 1))
      navigationController.navigationBar.shadowImage = image
      navigationController.navigationBar.setBackgroundImage(image, for: .any, barMetrics: .default)
      navigationController.navigationBar.isTranslucent = false
      
      return navigationController
    }
    
    private func _createImage(size: CGSize, color: UIColor = .white) -> UIImage? {
      UIGraphicsBeginImageContext(size)
      defer { UIGraphicsEndImageContext() }
      
      guard let context = UIGraphicsGetCurrentContext() else { return nil }
      
      context.setFillColor(color.cgColor)
      context.fill(CGRect(origin: .zero, size: size))
      return UIGraphicsGetImageFromCurrentImageContext()
    }
  }
}

// MARK: - Localization

internal func _UILocalizedString(for key: String) -> String? {
  let value = Russell.userInterfaceLocalizedStringTable.string(for: key)
  guard value != "Russell-unknown" else { return nil }
  return value
}

internal func _UISafeLocalizedString(for key: String) -> String {
  return Russell.userInterfaceLocalizedStringTable.string(for: key)
}
