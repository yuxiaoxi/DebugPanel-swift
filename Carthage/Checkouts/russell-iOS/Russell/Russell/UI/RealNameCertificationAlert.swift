//
//  RealNameCertificationAlert.swift
//  Russell
//
//  Created by Yunfan Cui on 2019/7/22.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit

enum RealNameCertificationNotice: String, Notice {
  case confirmWeakBinding // confirm to use weak binding flow
  case bindMobile // weak bound mobile expired, or no mobile bound
  case sessionExpired // binding session expired
}

enum RealNameCertificationAlert: String, Alert {
  case mobileAlreadyBound // for 3rd party account registration / email code registration / re-bind for weak bound mobile
  case weakBoundExpiring // weak bound mobile is close to expire date
  case waitForDelayedMobileCode // wait for sms code
}
