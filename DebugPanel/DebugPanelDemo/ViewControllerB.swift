//
//  ViewControllerB.swift
//  DebugPanelDemo
//
//  Created by zhuo yu on 2019/9/5.
//  Copyright © 2019 zhuo yu. All rights reserved.
//

import UIKit
import LLSRouterController

@objc(ViewControllerB)
class ViewControllerB: RouterViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let contentLabel: UILabel = UILabel()
    contentLabel.frame = CGRect.init(x: 59, y: 100, width: 100, height: 30)
    contentLabel.text = "测试B"
    self.view.addSubview(contentLabel)
    self.view.backgroundColor = UIColor.white
    self.navigationItem.title = "DemoB"
    let button: UIButton = UIButton(type: .roundedRect)
    button.frame = CGRect(x: 59, y: 140, width: 100, height: 30)
    button.backgroundColor = UIColor.groupTableViewBackground
    button.setTitleColor(UIColor.black, for: .normal)
    button.titleLabel!.font = UIFont.systemFont(ofSize: 13)
    button.setTitle("我是按钮", for: .normal)
    button.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
    self.view.addSubview(button)
  }
  
  @objc func buttonClick() {
    let viewcontroller = UIViewController()
    viewcontroller.title = "页面"
    viewcontroller.view.backgroundColor = UIColor.yellow
    self.navigationController?.pushViewController(viewcontroller, animated: true)
  }
  
  override func handleWithURLAction(urlAction: URLAction) -> Bool {
    print("----->", urlAction.stringForKey(key: "aaa"))
    return super.handleWithURLAction(urlAction: urlAction)
  }
}
