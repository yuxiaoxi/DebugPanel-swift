//
//  NSURL+Ext.swift
//  LLSRouterController
//
//  Created by zhuo yu on 2019/9/6.
//  Copyright © 2019 LAIIX. All rights reserved.
//

import UIKit

extension NSURL {
  
  func parseQuery() -> Dictionary<String, String> {
    let query = self.query
    
    var dict = [String: String]()
    let paris = query?.split(separator: "&") ?? []
    
    for pari in paris {
      let elements = pari.split(separator: "=")
      if elements.count <= 1 {
        continue
      }
      let key: String = elements[0].removingPercentEncoding!
      let originValue: CFString = CFURLCreateStringByReplacingPercentEscapes(nil, ((elements[1]) as CFString), "" as CFString)
      let oriValue: String = originValue as String
      if oriValue.count > 0 {
        dict[key] = oriValue
      }
    }
    return dict
  }

}
