//
//  AppDelegate.swift
//  DebugPanelDemo
//
//  Created by zhuo yu on 2019/8/28.
//  Copyright © 2019 zhuo yu. All rights reserved.
//

import UIKit
import DebugPanel
import LLSRouterController

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    let window = UIWindow(frame: UIScreen.main.bounds)
    self.window = window
    let navigationViewController = BaseNavigationController(rootViewController: ViewController())
    window.rootViewController = navigationViewController
    window.makeKeyAndVisible()
    let navigator = LLSNavigator.navigator
    navigator.configHandleableUrlScheme(scheme: "lls")
    navigator.configFileNameOfURLMapping(fileName: "urlmapping")
    navigator.configMainNavigationViewController(mainNavigationViewController: navigationViewController)
    //通过回调方式注册 debug 面板
//    debugConfigurationByBlock()
    //通过protocol方式注册 debug 面板
    #if DEBUG
    debugConfigurationByProtocol()
    #endif
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
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }

}

// MARK: debugpanel register by block
extension AppDelegate {
  
  func debugConfigurationByBlock() {
    let debugBar = LLSDebugBar.startDebugPanel(true)
    
    debugBar?.addExtentsionButton("test1", buttonStyle: DebugBarButtonStyle.ROWHASTWO) {
      print("----test1")
    }
    debugBar?.addExtentsionButton("test", buttonStyle: DebugBarButtonStyle.ROWHASTWO) {
      print("----test")
    }
    debugBar?.addExtentsionButton("test2", buttonStyle: DebugBarButtonStyle.ROWHASONE) {
      print("----test2")
    }
    
    debugBar?.configCommonOperattion(.oneKeyProduct) {
      print("----onekeyproduct")
    }
    debugBar?.configCommonOperattion(.oneKeyStaging) {
      print("----onekeystaging")
    }
    debugBar?.openURLByRouter(.routerURL) { urlStr in
      print("----openURLByRouter", urlStr)
    }
    debugBar?.configCommonOperattion(.openDebugPanel) {
      print("----openDebugPanel")
    }
  }
}

// MARK: debugpanel register by protocol
extension AppDelegate: LLSDebugProtocol {
  
  func debugConfigurationByProtocol() {
    let debugBar = LLSDebugBar.startDebugPanel(true)
    
    debugBar?.addExtentsionButton("扫一扫", buttonStyle: DebugBarButtonStyle.ROWHASTWO) {
      print("---->扫一扫点击了")
    }
    debugBar?.addExtentsionButton("测试1", buttonStyle: DebugBarButtonStyle.ROWHASTWO) {
      print("---->测试1点击了")
    }
    debugBar?.addExtentsionButton("test2", buttonStyle: DebugBarButtonStyle.ROWHASONE) {
      print("----test2")
    }
    debugBar?.addExtensionSwitch("switch1", true, completion: { isOn in
       print("----switch1", isOn)
    })
    debugBar?.addExtensionSwitch("switch2", false, completion: { isOn in
       print("----switch2", isOn)
    })
    debugBar?.debugDelegate = self
  }
  
  func oneKeyProduct() {
    print("----onekeyproduct")
  }
  
  func oneKeyStaging() {
    print("----onekeystaging")
  }
  
  func oneKeyDev() {
    print("----oneKeyDev")
  }
  
  func openURLByRouter(_ urlStr: String) {
    print("----openURLByRouter", urlStr)
    _ = LLSNavigator.navigator.openURLString(urlString: urlStr)
  }
  
  func openDebugPanel() {
    print("----openDebugPanel")
  }
}
