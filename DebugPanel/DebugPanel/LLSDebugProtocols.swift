//
//  LLSDebugProtocols.swift
//  DebugPanel
//
//  Created by zhuo yu on 2019/9/5.
//  Copyright © 2019 zhuo yu. All rights reserved.
//

import UIKit

/// DebugPanel protocol
public protocol LLSDebugProtocol {
  
  /// operation： 设置一键 product 的点击事件
  /// operation 中需要操作的内容包括：
  /// 1、退出登录
  /// 2、清除登录的缓存和文件信息
  /// 3、关掉当前页面并跳转至登录界面
  func oneKeyProduct() -> Void
  
  /// operation： 设置一键 staging 的点击事件
  /// operation 中需要操作的内容包括：
  /// 1、退出登录
  /// 2、清除登录的缓存和文件信息
  /// 3、关掉当前页面并跳转至登录界面
  func oneKeyStaging() -> Void
  
  /// operation： 设置一键 Dev 的点击事件
  /// operation 中需要操作的内容包括：
  /// 1、退出登录
  /// 2、清除登录的缓存和文件信息
  /// 3、关掉当前页面并跳转至登录界面
  func oneKeyDev() -> Void
  
  /// openURLByRouter： 设置 openURL 的点击事件
  /// openURLByRouter 中需要操作的内容包括：
  /// 需要设置路由跳转
  func openURLByRouter(_ urlStr: String) -> Void
  
  /// openDebugPanel： 设置 openDebugPanel 的点击事件
  /// openDebugPanel 中需要操作的内容包括：
  /// 需要设置跳转至debug info界面
  func openDebugPanel() -> Void
}
