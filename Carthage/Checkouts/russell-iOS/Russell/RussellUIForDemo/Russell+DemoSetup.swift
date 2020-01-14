//
//  Russell+DemoSetup.swift
//  RussellUIForDemo
//
//  Created by Yunfan Cui on 2018/12/29.
//  Copyright © 2018 LLS. All rights reserved.
//

import Russell
import SafariServices

private enum PoolID {
  static let withGeeTest = "test-geetest-poolid"
}

extension Russell {
  
  public static func setupForStagingDemo(deviceID: String, dataTracker: DataTracker) {
    let configuration = Russell.Configuration(
      urlConfiguration: .defaultDev,
      poolID: PoolID.withGeeTest,
      deviceID: deviceID,
      appID: "lls",
      tokenStorage: KeyChainTokenStorage(),
      dataTracker: dataTracker) { container in
        container.present(SFSafariViewController(url: URL(string: "https://www.liulishuo.work")!), animated: true, completion: nil)
    }
    
    setup(configuration: configuration)
  }
  
  public static func demoLoginNavigationController() -> UINavigationController {
    let root = SMSLoginViewController(nibName: "SMSLoginViewController", bundle: Bundle(for: SMSLoginViewController.self))
    
    let coordinator = SMSLoginSessionCoordinator()
    root.coordinator = coordinator
    coordinator.enterMobileViewController = root
    
    let navigationController = UINavigationController(rootViewController: root)
    coordinator.navigationController = navigationController
    
    return navigationController
  }
  
  public static func demoPasswordLoginNavigationController() -> UINavigationController {
    return UINavigationController(rootViewController: PasswordLoginViewController(nibName: "PasswordLoginViewController", bundle: Bundle(for: PasswordLoginViewController.self)))
  }
  
  public static func demoOneKeyLoginByPhoneNavigationController() -> UINavigationController {
    return UINavigationController(rootViewController: TXNumberCheckViewController(nibName: "TXNumberCheckViewController", bundle: Bundle(for: TXNumberCheckViewController.self)))
  }
}
