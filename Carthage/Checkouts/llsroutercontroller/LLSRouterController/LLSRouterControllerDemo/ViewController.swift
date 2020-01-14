//
//  ViewController.swift
//  LLSRouterControllerDemo
//
//  Created by zhuo yu on 2019/9/5.
//  Copyright © 2019 LAIIX. All rights reserved.
//

import UIKit
import LLSRouterController

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    self.title = "首页"
    let button: UIButton = UIButton(type: .roundedRect)
    button.frame = CGRect(x: 59, y: 140, width: 100, height: 30)
    button.backgroundColor = UIColor.groupTableViewBackground
    button.setTitleColor(UIColor.black, for: .normal)
    button.titleLabel!.font = UIFont.systemFont(ofSize: 13)
    button.setTitle("我是按钮", for: .normal)
    button.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
    self.view.addSubview(button)
    // Do any additional setup after loading the view.
  }

  @objc func buttonClick() {
    _ = LLSNavigator.navigator.openURLString(urlString: "llss://firstVC?aaa=1")
  }

}

