//
//  RouterViewController.swift
//  LLSRouterController
//
//  Created by zhuo yu on 2019/9/9.
//  Copyright © 2019 LAIIX. All rights reserved.
//

import UIKit

public protocol RouterViewControllerProtocal {
  func handleWithURLAction(urlAction: URLAction) -> Bool
}

open class RouterViewController: UIViewController {
  
}

extension RouterViewController: RouterViewControllerProtocal {
  
  open override func handleWithURLAction(urlAction: URLAction) -> Bool {
    self.urlAction = urlAction
    return true
  }
}

extension UIViewController {
  
  @objc
  public func handleWithURLAction(urlAction: URLAction) -> Bool {
    return true
  }
}
