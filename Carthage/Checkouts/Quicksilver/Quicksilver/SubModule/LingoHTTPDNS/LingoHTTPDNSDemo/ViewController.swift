//
//  ViewController.swift
//  LingoHTTPDNSDemo
//
//  Created by Chun on 09/03/2018.
//  Copyright © 2018 LLS iOS Team. All rights reserved.
//

import UIKit
import LingoHTTPDNS

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    let domain = "liulishuo.com"
    if let result = HTTPDNS.query(domain) {
      print("这个时候应该没有结果 \(result)")
    } else {
      let delayTime = DispatchTime.now() + Double(Int64(5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
      DispatchQueue.main.asyncAfter(deadline: delayTime) {
        if let result = HTTPDNS.query(domain) {
          print(result.ip)
          print(HTTPDNS.getOriginDomain(ipAddress: result.ipAddress) ?? "nil domain")
        }
      }
    }
  }

}
