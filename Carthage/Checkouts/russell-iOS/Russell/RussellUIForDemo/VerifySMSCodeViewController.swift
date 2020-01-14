//
//  VerifySMSCodeViewController.swift
//  RussellDemo
//
//  Created by Yunfan Cui on 2018/12/18.
//  Copyright © 2018 LLS. All rights reserved.
//

import UIKit

final class VerifySMSCodeViewController: UIViewController {
  
  @IBOutlet private weak var smsField: UITextField!
  @IBOutlet weak var resultLabel: UILabel!
  
  var coordinator: SMSLoginSessionCoordinator?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
  }
  
  @objc private func close() {
    dismiss(animated: true, completion: nil)
  }
  
  @IBAction private func verify() {
    guard let code = smsField.text else {
      return
    }
    
    coordinator?.verifySMSCode(code)
  }
  
  @IBAction private func resendSMS() {
    coordinator?.resendSMS()
  }
}
