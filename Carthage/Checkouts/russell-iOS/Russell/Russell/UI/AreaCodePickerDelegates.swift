//
//  MobileInputCoordinator.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/7/23.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit

protocol AreaCodeSelectionDelegate: class {
  func updateSelection(_ dailCode: String)
}

protocol AreaCodePickerDelegate: AreaCodeSelectionDelegate {
  func areaCodePickerDismissed()
  func presentAreaCodeSearcher()
}
