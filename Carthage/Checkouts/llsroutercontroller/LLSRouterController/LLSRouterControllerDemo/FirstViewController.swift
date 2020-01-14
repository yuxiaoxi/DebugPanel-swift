//
//  FirstViewController.swift
//  LLSRouterControllerDemo
//
//  Created by zhuo yu on 2019/10/10.
//  Copyright © 2019 LAIIX. All rights reserved.
//

import UIKit
import LLSRouterController

@objc(FirstViewController)
class FirstViewController: RouterViewController {
  private var parmAAA: String?
  override func viewDidLoad() {
    super.viewDidLoad()
    self.title = "第一个页面"
    self.view.backgroundColor = UIColor.white
    
    let label: UILabel = UILabel()
    label.text = "通过scheme跳转过来的,参数:" + (parmAAA ?? "")
    label.frame = CGRect(x: 59, y: 140, width: 100, height: 30)
    label.sizeToFit()
    label.textColor = UIColor.black
    self.view.addSubview(label)
    // Do any additional setup after loading the view.
  }
  
  override func handleWithURLAction(urlAction: URLAction) -> Bool {
    parmAAA = urlAction.stringForKey(key: "aaa")
    return super.handleWithURLAction(urlAction: urlAction)
  }
  
}
