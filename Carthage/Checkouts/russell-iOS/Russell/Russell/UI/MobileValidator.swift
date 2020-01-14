//
//  MobileValidator.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/9/2.
//  Copyright © 2019 LLS. All rights reserved.
//

import Foundation

enum MobileValidator {
  
  static func isValidMobile(dialCode: String, mobile: String) -> Bool {
    guard !mobile.isEmpty else { return false }
    
    switch dialCode {
    case "+86":
      return mobile.count == 11 && mobile.first == "1"
    default:
      return true
    }
  }
}
