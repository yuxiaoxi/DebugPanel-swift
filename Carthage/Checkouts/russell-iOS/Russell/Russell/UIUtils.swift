//
//  UIUtils.swift
//  Russell
//
//  Created by zhuo yu on 2019/10/24.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit

extension UIColor {
  /// string to UIColor
  /// - Parameter hexString: color string
  public static func colorWithHexString(_ hexString: String) -> UIColor {
    let hexString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
    let scanner = Scanner(string: hexString)
    
    if hexString.hasPrefix("#") {
      scanner.scanLocation = 1
    }
    
    if hexString.hasPrefix("0X") {
      scanner.scanLocation = 2
    }
    
    var color: UInt32 = 0
    scanner.scanHexInt32(&color)
    
    let mask = 0x000000FF
    let r = Int(color >> 16) & mask
    let g = Int(color >> 8) & mask
    let b = Int(color) & mask
    
    let red   = CGFloat(r) / 255.0
    let green = CGFloat(g) / 255.0
    let blue  = CGFloat(b) / 255.0
    
    return UIColor.init(red: red, green: green, blue: blue, alpha: 1)
  }
}
