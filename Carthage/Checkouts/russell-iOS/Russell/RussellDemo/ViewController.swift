//
//  ViewController.swift
//  RussellDemo
//
//  Created by Yunfan Cui on 2018/12/10.
//  Copyright © 2018 LLS. All rights reserved.
//

import UIKit
import Loki
import SVProgressHUD
import Russell
import RussellUIForDemo

typealias HUD = SVProgressHUD

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    let key = "Okj0Uid+slNGLCihLtwd3L2asaUR3plcUvCNdiielJYGoZhBtattjs2T1AQG5Wyh1YoN9gefazvwqfo0/NP494H2IE+O0KOEqGpuvE177E8n5+AVXx6Ql76fXc1KOeEyZcxznIk68vJKJeDm6u9t+vHrvNfR5LdHWEeGORxR2nIHYmwXf4GWURBe8Zg9clYiY1krrL27thnwqBHKqWsrsOfqXr2hQgyVUCFZY4OMijudQxLafV0YhuyZofj5/vwG"
    Russell.OneKeyLoginFlow.setAuthSDKInfo(key: key, phoneNumber: "", retriesOnceOnNetworkFailure: true, networkConnectionListeningTimeout: 2.0) { isAccessible, resultInfo in
      
      print("onekey setup content: [\(String(describing: resultInfo))]")
    }
  }
  
  @IBAction private func showSMS(_ sender: UIButton) {
    present(Russell.demoLoginNavigationController(), animated: true, completion: nil)
  }
  
  @IBAction private func showPassword(_ sender: UIButton) {
    present(Russell.demoPasswordLoginNavigationController(), animated: true, completion: nil)
  }
  
  @IBAction private func oneKeyLoginByPhone(_ sender: UIButton) {
    present(Russell.demoOneKeyLoginByPhoneNavigationController(), animated: true, completion: nil)
  }
}
