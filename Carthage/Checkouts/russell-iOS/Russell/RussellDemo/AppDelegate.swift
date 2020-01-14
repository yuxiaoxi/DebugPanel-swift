//
//  AppDelegate.swift
//  RussellDemo
//
//  Created by Yunfan Cui on 2018/12/10.
//  Copyright © 2018 LLS. All rights reserved.
//

import UIKit
import Russell
import RussellUIForDemo
import LingoUDID
import Loki
import SVProgressHUD
import LingoLog
import SafariServices
import Tachikoma
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

public struct LLSShareService {
  public static let qqId = "100383694"
  
  public static let weiboId = "4254593945"
  public static let weiboRedirectURL = "http://www.liulishuo.com"
  
  public static let wechatId = "wx29d28524d6eaf623"
  public static let wechatServerURL = URL(string: "https://wx.thellsapi.com")!
  
  public static let appleLogined = "signinwithappleed"
}

typealias ThirdParty = Loki.ServiceManager

class MemoryTokenStorage: TokenStorage {
  var token: Token?
}

private enum PoolID {
  static let withGeeTest = "test-geetest-poolid"
  static let thirdParty = "test-auto-create-poolid"
  static let nonAutoRegistration = "test-poolid"
  static let realName = "lingochamp-app"
  static let realNameAndroid = "real-name-android"
  static let onekeyBinderTest = "c1f598631ca73c736cd18b46f1a0311b"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    if #available(iOS 13.0, *) {
      observeAuthticationState()
    }
    
    let deviceID = LingoCommonUDID.deviceId()
//    let deviceID = "bf8d570824265fa8e851bf5fbff154b36de415d5"
    // Tracking
    let trackingLogger = TachikomaLogger(targetLevel: .debug) { (message) in
      LingoLog.Logger.log(level: .debug, message: message, tag: "Russell-Tracking")
    }
    TachikomaProvider.start(appName: "russell_sdk", password: "dummy-pass", deviceId: deviceID, uid: "russell-ios-sdk", logger: trackingLogger)
    TachikomaProvider.updateConfiguration(from: URL(string: "http://staging-neo.llsapp.com/api/v1")!, path: "/api/data/config")
    let russellTracker = RussellTracker()
    
    // Setup Russell
//        Russell.setupForStagingDemo(deviceID: LingoCommonUDID.deviceId())
    let configuration = Russell.Configuration(
      urlConfiguration: .defaultDev,
      poolID: PoolID.onekeyBinderTest,
      deviceID: deviceID,
      appID: "lls",
      tokenStorage: KeyChainTokenStorage(),
      dataTracker: russellTracker) { container in
        container.present(SFSafariViewController(url: URL(string: "http://d.laix.xyz")!), animated: true, completion: nil)
    }
    Russell.setup(configuration: configuration)
    Russell.localizedStringTable = .init(bundle: .main, table: "xxx")
    Russell.UI.headsUpDisplay = HUDWrapper()
    
    // Logger
    LoggerTool.appendLiveLogOutput(filterRule: LogFilterRule(minLevel: .debug, tagComparison: nil))
    LoggerTool.appendIDEOutput(filterRule: LogFilterRule(minLevel: .verbose, tagComparison: nil), asynchronously: false)
    RussellLogger.setup(output: RussellOutput())
    
    #if targetEnvironment(simulator)
    #else
    // loki
    ServiceManager.register(forType: .qq, withLaunchOptions: .qq(appId: LLSShareService.qqId))
    ServiceManager.register(forType: .weibo, withLaunchOptions: .weibo(appId: LLSShareService.weiboId, redirectUrlStr: LLSShareService.weiboRedirectURL, debugMode: false))
    
    ServiceManager.register(forType: .wechat, withLaunchOptions: .wechat(appId: LLSShareService.wechatId, serverURL: LLSShareService.wechatServerURL))
    #endif
    
    return true
  }
  
  func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    _ = ServiceManager.handleOpenURL(url, forType: .wechat)
    _ = ServiceManager.handleOpenURL(url, forType: .qq)
    _ = ServiceManager.handleOpenURL(url, forType: .weibo)
    return true
  }
  
  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }
  
  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }
  
  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    Russell.shared?.fetchRealNameInfo { result in
      guard let controller = self.window?.rootViewController,
        let info = try? result.get(),
        info.needsBinding
        else { return }
      let config = info.toBindingConfiguration(hasUserConfirmedPrivacyInfo: true)
      Russell.UI.warnRealName(in: .presentation(controller), message: info.message, showsWarningWhenExpired: true, configuration: config, completion: { _ in })
    }
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
  ///查看apple登录授权状态
  @available(iOS 13.0, *)
  func observeAuthticationState () {
    let userID = KeychainItem.currentUserIdentifier("com.liulishuo.engzo2")
    let appleIDProvider = ASAuthorizationAppleIDProvider()
    appleIDProvider.getCredentialState(forUserID: userID) { credentialState, error in
      switch credentialState {
      case .authorized:
        // 身份权限正常使用.
        UserDefaults.standard.set(true, forKey: LLSShareService.appleLogined)
      case .revoked:
        // 身份权限过期
        fallthrough
      case .notFound:
        // 没有找到授权
        UserDefaults.standard.set(false, forKey: LLSShareService.appleLogined)
      default:
        break
      }
    }
  }
}

// MARK: - Russell Injection

private struct RussellOutput: RussellLoggerOutput {
  
  func log(level: RussellLogger.Level, file: String, function: String, line: Int, message: () -> Any) {
    LingoLog.Logger.log(level: LingoLog.LogLevel(rawValue: level.rawValue) ?? .debug, message: message(), tag: "Russell")
  }
}

private class HUDWrapper: HeadsUpDisplay {
  
  func show() {
    SVProgressHUD.show()
  }
  
  func show(_ message: String) {
    SVProgressHUD.show(withStatus: message)
  }
  
  func showInfo(_ message: String) {
    SVProgressHUD.showInfo(withStatus: message)
  }
  
  func showSuccess(_ message: String) {
    SVProgressHUD.showSuccess(withStatus: message)
  }
  
  func showError(_ message: String) {
    SVProgressHUD.showError(withStatus: message)
  }
  
  func dismiss() {
    SVProgressHUD.dismiss()
  }
}

private class RussellTracker: DataTracker {
  
  func enterPage(pageName: String, pageCategory: String, properties: [String : Any]?) {
    LLSStat.enterPage(pageName, category: pageCategory, extra: properties)
  }
  
  func action(actionName: String, pageCategory: String, pageName: String, properties: [String : Any]?) {
    let pageInfo = RussellTypeBox(pageCategory) ~>> RussellTypeBox(pageName)
    LaixTracker.current.action(RussellTypeBox(actionName), page: pageInfo, more: properties?.trackedProperties ?? [])
  }
  
  func action(actionName: String, properties: [String : Any]?) {
    LLSStat.action(actionName, withParamters: properties)
  }
}

struct RussellTypeBox: Action, Issue, Page, PageCategory {
  let description: String
  
  init(_ rawValue: String) {
    self.description = rawValue
  }
}
