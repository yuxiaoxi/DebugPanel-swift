//
//  PNSReturnCode.h
//  ATAuthSDK
//
//  Created by 刘超的MacBook on 2019/9/4.
//  Copyright © 2019 alicom. All rights reserved.
//

#ifndef PNSReturnCode_h
#define PNSReturnCode_h

#import <Foundation/Foundation.h>

/// iOS接口成功
static NSString * const PNSCodeSuccess = @"600000";
/// 唤起授权页成功
static NSString * const PNSCodePresentLoginControllerSuccess = @"600001";
/// 唤起授权页失败
static NSString * const PNSCodePresentLoginControllerFailed = @"600002";
/// 点击返回，⽤户取消一键登录
static NSString * const PNSCodeCancelLogin = @"600003";
/// 获取运营商配置信息失败
static NSString * const PNSCodeGetOperatorInfoFailed = @"600004";
/// 未检测到sim卡
static NSString * const PNSCodeNoSIMCard = @"600007";
/// 蜂窝网络未开启
static NSString * const PNSCodeNoCellularNetwork = @"600008";
/// 无法判运营商
static NSString * const PNSCodeUnknownOperator = @"600009";
/// 未知异常
static NSString * const PNSCodeUnknownError = @"600010";
/// 获取token失败
static NSString * const PNSCodeGetTokenFailed = @"600011";
/// 预取号失败
static NSString * const PNSCodeGetMaskPhoneFailed = @"600012";
/// 运营商维护升级，该功能不可用
static NSString * const PNSCodeInterfaceDemoted = @"600013";
/// 运营商维护升级，该功能已达最大调用次数
static NSString * const PNSCodeInterfaceLimited = @"600014";
/// 接口超时
static NSString * const PNSCodeInterfaceTimeout = @"600015";
/// 点击切换按钮，⽤户取消免密登录
static NSString * const PNSCodeChangeLoginWay = @"600016";
/// AppID、Appkey解析失败
static NSString * const PNSCodeDecodeAppInfoFailed = @"600017";

#endif /* PNSReturnCode_h */
