//
//  LoggedInListViewController.swift
//  RussellDemo
//
//  Created by Yunfan Cui on 2019/2/22.
//  Copyright © 2019 LLS. All rights reserved.
//

import Russell
import UIKit

final class LoggedInListViewController: UIViewController {
  
  @IBOutlet private weak var hintLabel: UILabel!
  @IBOutlet private weak var stack: UIStackView!
  
  override func viewDidLoad() {
    let isLoggedIn = Russell.shared?.authorizationToken() != nil
    
    hintLabel.isHidden = isLoggedIn
    stack.isHidden = !isLoggedIn
    
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(close))
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Log out", style: .plain, target: self, action: #selector(logout))
  }
  
  @objc private func close() {
    dismiss(animated: true, completion: nil)
  }
  
  @objc private func logout() {
    Russell.shared?.logout()
  }
  
  @IBAction private func _boundMobile(_ sender: AnyObject?) {
    Russell.UI.showBoundMobile(in: .navigation(navigationController!))
  }
}
