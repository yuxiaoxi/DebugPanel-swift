//
//  TestViewController.swift
//  QuicksilverDemo
//
//  Created by Chun on 2018/5/23.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import UIKit
import Quicksilver

class TestViewController: UIViewController {
  
  var darwinAPI: QuicksilverProvider!
  
  deinit {
    print("TestViewController deinit")
  }
  
  private let reachability = Reachability()!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    reachability.startListening()
    
    let requestPlugin = DarwinAPIRequestPlugin()
    let tokenPlugin = AccessTokenPlugin(tokenClosure: token)
    let configuration = QuicksilverURLSessionConfiguration(useHTTPDNS: false)
    darwinAPI = QuicksilverProvider(configuration: configuration, plugins: [requestPlugin, tokenPlugin, NetworkLoggerPlugin(cURL: true, output: nil)])
    var task: QuicksilverTask!
    task = darwinAPI.request(DarwinLoginRouter.fetchSessionsCode(mobileNumber: "18652929750")) { (result) in
      if let value = try? result.get(), let json = try? value.mapJSON() {
        print(json)
      }
      print("task.isRunning at end \(task.isRunning)")
    }
    print("task.isRunning at start \(task.isRunning)")

    darwinAPI.configuration.useHTTPDNS = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      print(self.reachability.isReachable)
    }
  }

}
