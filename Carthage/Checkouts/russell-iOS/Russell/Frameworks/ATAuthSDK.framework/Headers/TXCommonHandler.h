//
//  TXCommonHandler.h
//  ATAuthSDK
//
//  Created by yangli on 15/03/2018.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TXCommonHandler : NSObject

/**
 *  获取该类的单例实例对象
 *  @return  单例实例对象
 */
+ (instancetype _Nonnull)sharedInstance;

/**
 *  获取当前SDK版本号
 *  @return  字符串，sdk版本号
 */
- (NSString *_Nonnull)getVersion;

/**
 *  初始化SDK调用参数，app生命周期内调用一次
 *  @param  info app对应的秘钥
 *  @param  complete 结果同步回调，成功时resultDic=@{resultCode:600000, msg:...}，其他情况时"resultCode"值请参考PNSReturnCode
 */
- (void)setAuthSDKInfo:(NSString * _Nonnull)info complete:(void(^_Nullable)(NSDictionary * _Nonnull resultDic))complete;

/**
 *  检查及准备调用环境，返回YES才能调用下面的功能接口，在初次或切换蜂窝网络之后需要重新调用，一般在一次登录认证流程开始前调一次即可
 *  @param  phoneNumber 手机号码，非必传
 *  @param  complete 结果同步回调，返回YES时resultDic=@{resultCode:600000, msg:...}，其他情况时"resultCode"值请参考PNSReturnCode
 *  @return BOOL值，YES表示调用接口环境准备完毕，只有YES才能保障后续服务
 */
- (BOOL)checkEnvAvailable:(NSString *_Nullable)phoneNumber complete:(void (^_Nullable)(NSDictionary * _Nullable resultDic))complete;

/**
 *  获取本机号码校验Token
 *  @param  timeout 接口超时时间，单位s，默认为3.0s
 *  @param  complete 结果异步回调，成功时resultDic=@{resultCode:600000, token:..., msg:...}，其他情况时"resultCode"值请参考PNSReturnCode
 */
- (void)getVerifyTokenWithTimeout:(NSTimeInterval )timeout complete:(void (^_Nullable)(NSDictionary * _Nonnull resultDic))complete;

/**
 *  获取一键登录手机掩码
 *  @param  timeout 接口超时时间，单位s，默认为3.0s
 *  @param  complete 结果异步回调，成功时resultDic=@{resultCode:600000, number:..., operatorId:..., privacyName:..., privacyUrl:..., msg:...}，其他情况时"resultCode"值请参考PNSReturnCode，number为获取的手机掩码，operatorId运营商id（1-移动，2-联通，3-电信），privacyName为隐私条款名，privacyUrl为隐私条款对应的URL
 */
- (void)getMaskPhoneWithTimeout:(NSTimeInterval )timeout complete:(void (^_Nullable)(NSDictionary * _Nonnull resultDic))complete;

/**
 *  获取一键登录Token
 *  @param  timeout 接口超时时间，单位s，默认为3.0s
 *  @param  controller 自定义授权页，内部会对其进行验证，检查是否符合条件
 *  @param  complete 结果异步回调，成功时resultDic=@{resultCode:600000, token:..., msg:...}，，其他情况时"resultCode"值请参考PNSReturnCode
 */
- (void)getLoginTokenWithTimeout:(NSTimeInterval )timeout controller:(UIViewController *_Nonnull)controller complete:(void (^_Nullable)(NSDictionary * _Nonnull resultDic))complete;

/**
 *  设置日志上传开关
 *  @param  enable 开关设置BOOL值，默认为YES
 */
- (void)setUploadEnable:(BOOL)enable;

/**
 * 删除预取号缓存
 */
- (void)deleteCache;

/*
 * 函数名：checkGatewayVerifyEnable，初始化接口
 * 参数：phoneNumber，手机号码，非必传，号码认证且双sim卡时必须传入待验证的手机号码！！，一键登录时设置为nil即可
 * 返回：BOOL值，YES表示网关认证所需的蜂窝数据网络已开启，其SDK初始化成功，否则是NO，只有YES才能保障后续服务
 */
- (BOOL)checkGatewayVerifyEnable:(NSString *_Nullable)phoneNumber DEPRECATED_MSG_ATTRIBUTE("Please use checkEnvAvailable: instead");

/****************************以下接口是号码认证接口*******************************/

/*
 * 函数名：getAuthTokenWithComplete，号码认证Token，默认超时时间3.0s
 * 参数：无
 * 返回：字典形式
 *      resultCode：6666-成功，5555-超时，4444-失败，3344-参数异常，2222-无网络，1111-无SIM卡
 *      token：号码认证token
 *      msg：文案或错误提示
 */

- (void)getAuthTokenWithComplete:(void (^_Nullable)(NSDictionary * _Nonnull resultDic))complete DEPRECATED_MSG_ATTRIBUTE("Please use getVerifyTokenWithTimeout:complete: instead");

/*
 * 函数名：getAuthTokenWithTimeout，号码认证Token，可设置超时时间
 * 参数：timeout：接口超时时间，单位s，默认3.0s，值为0.0时采用默认超时时间
 * 返回：字典形式
 *      resultCode：6666-成功，5555-超时，4444-失败，3344-参数异常，2222-无网络，1111-无SIM卡
 *      token：号码认证token
 *      msg：文案或错误提示
 */

- (void)getAuthTokenWithTimeout:(NSTimeInterval )timeout complete:(void (^_Nullable)(NSDictionary * _Nonnull resultDic))complete DEPRECATED_MSG_ATTRIBUTE("Please use getVerifyTokenWithTimeout:complete: instead");


/****************************以下接口是无UI的一键登录接口*******************************/

/*
 * 函数名：getLoginNumberWithTimeout，一键登录预取号
 * 参数：
 timeout：接口超时时间，单位s，默认3.0s，值为0.0时采用默认超时时间
 * 返回：字典形式
 *      resultCode：6666-成功，5555-超时，4444-失败，3344-参数异常，2222-无网络，1111-无SIM卡
 *      number：手机掩码
 *      operateId：运营商Id，1-移动，2-联通，3-电信
 *      privacyName：运营商服务协议名称
 *      privacyUrl：运营商服务协议url
 *      msg：文案或错误提示
 */

- (void)getLoginNumberWithTimeout:(NSTimeInterval )timeout complete:(void (^_Nullable)(NSDictionary * _Nonnull resultDic))complete DEPRECATED_MSG_ATTRIBUTE("Please use getMaskPhoneWithTimeout:complete: instead");

/*
 * 函数名：getLoginTokenWithTimeout，一键登录Token
 * 参数：
   vc：授权vc容器，即一键登录授权页面
   timeout：接口超时时间，单位s，默认3.0s，值为0.0时采用默认超时时间
 * 返回：字典形式
 *      resultCode：6666-成功，5555-超时，4444-失败，3344-参数异常，2222-无网络，1111-无SIM卡
 *      token：一键登录token
 *      msg：文案或错误提示
 */

- (void)getLoginTokenWithController:(UIViewController *_Nonnull)vc timeout:(NSTimeInterval )timeout complete:(void (^_Nullable)(NSDictionary * _Nonnull resultDic))complete DEPRECATED_MSG_ATTRIBUTE("Please use getLoginTokenWithTimeout:controller:complete: instead");


@end
