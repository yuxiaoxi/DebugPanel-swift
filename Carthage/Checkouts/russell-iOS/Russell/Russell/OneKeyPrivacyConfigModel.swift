//
//  OneKeyPrivacyConfigModel.swift
//  Russell
//
//  Created by zhuo yu on 2019/10/16.
//  Copyright © 2019 LLS. All rights reserved.
//

import UIKit

/// 获取到手机掩码运营商相关信息
public struct OneKeyPrivacyConfigModel {
  
  /// 手机掩码号
  public let number: String
  
  /// 结果 code “600000”表示成功
  public let resultCode: String
  
  /// 运营商名称
  public let privacyName: String
  
  /// 操作 id
  public let operatorId: Int64
  
  /// 运营商同意协议
  public let privacyUrl: String
  public init(number: String, resultCode: String, privacyName: String, operatorId: Int64, privacyUrl: String) {
    self.number = number
    self.resultCode = resultCode
    self.privacyName = privacyName
    self.operatorId = operatorId
    self.privacyUrl = privacyUrl
  }
}
