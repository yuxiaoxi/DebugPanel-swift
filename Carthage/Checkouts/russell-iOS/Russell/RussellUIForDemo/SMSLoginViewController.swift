//
//  SMSLoginViewController.swift
//  RussellDemo
//
//  Created by Yunfan Cui on 2018/12/18.
//  Copyright © 2018 LLS. All rights reserved.
//

import UIKit

final class SMSLoginViewController: UIViewController {
  
  var coordinator: SMSLoginSessionCoordinator?
  
  @IBOutlet private weak var mobileField: UITextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(close))
  }
  
  @objc private func close() {
    dismiss(animated: true, completion: nil)
  }
  
  @IBAction private func login() {
    guard let mobile = mobileField.text else {
      return
    }
    
    coordinator?.sendSMSCode(to: mobile)
  }
}
