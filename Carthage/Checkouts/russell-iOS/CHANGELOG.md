# CHANGELOG

## [6.1.0] - 2019-10-30
### Changed
- 将一键登录的 SDK 从普通客户版本升级到大客户版本
- 将原来阿里提供的一键登录授权页改为自己定制方式
- 删掉了之前普通客户版本部分 API，如：`TXCustomModel` 整个废弃掉，以及相关的方法也同步废弃
- 删掉了 `OneKeyLoginDelegate` 以及修改了其注入的相关 API
- 更新了初始化、唤起授权页、点击登录按钮获取 token 并发出网络请求的 API

## [6.0.1] - 2019-10-22
### Added
- 新增手机号一键登录 SDK
- 将 ATSDK 升级至 2.6.10

## [Unreleased]
### Added
- 通过 Russell 获取四件套 Cookie

## [5.1.6] - 2019-09-24
### Changed
-添加手机号一键登录功能

## [5.1.2] - 2019-09-11
### Changed
- 强制手机绑定流程 present view controller 使用 `UIModalPresentationStyle.fullScreen`，以避免绑定手机流程在 iOS 13 中被用户操作取消，导致后续流程异常

## [5.1.1] - 2019-09-04
### Changed
- 集成 5.0.5 的相关改动

## [5.1.0] - 2019-09-04
### Added
- 新增 SignInWithApple 功能，详见[文档](README#sign-in-with-apple)

## [5.0.7] - 2019-09-18
### Changed
- Russell 配置增加 `appID` 参数

## [5.0.5] - 2019-09-04
### Changed
- 允许业务方注入配置，控制实名认证流程 UI 在结束之后是否自动关闭
- 限制手机号输入位数上限为 11 位
- +86 区号手机增加校验规则: 以 "1" 开头 && 位数必须为 11 位
- 用户点击重新发送验证码时，自动清空验证码输入框
- 绑定手机号成功以后，弹出绑定成功的 toast
- 优化手机号/验证码输入流程: 发送请求时收起键盘，必要时再自动弹出键盘

## [5.0.3] - 2019-09-02
### Fixed
- 修复 iOS 12 验证码自动填充的问题

## [5.0.2] - 2019-09-02
### Changed
- 优化 KeychainTokenStorage 存取服务

## [5.0.1] - 2019-08-28
### Fixed
- 修复打点问题

## [5.0.0] - 2019-08-27
### Added
- 新增[实名认证](README.md#实名认证)相关功能
- 新增 URL 配置 `defaultDev`，用于区分新的 Staging 和 Dev 环境

### Changed
- 初始化配置聚合成一个 `Russell.Configuration` 结构

## [4.3.0] - 2019-07-30
### Added
- 新增 Russell staging 环境的配置。原 `defaultStaging` 需要替换为 `defaultDev` 对应 Dev 环境，`defaultStaging` 现在对应的环境是 Staging.

### Changed
- SMS / Email 验证码相关流程现在在成功以后，也可以通过 resend verification code -> verify code 的流程复用了
- 重置密码更新了密码规则

### Fixed
- 修复“通过邮箱/手机号重置密码”流程成功以后，没有正常更新 token 的问题

## [4.2.0] - 2019-07-22
### Added
- `LoginResult` 增加 `passwordExists` 字段
- 增加使用旧密码更新密码的功能
- 增加获取/更新用户信息的功能

## [4.1.0] - 2019-07-12
### Added
- `LoginResult` 增加 `accessToken` 字段

## [3.3.0] - 2019-07-12
### Added
- `LoginResult` 增加 `accessToken` 字段

## [4.0.0] - 2019-6-26
### Added
- 针对“不自动注册账号”的 pool 配置，增加确认注册的流程

### Changed
- “不自动注册账号”的 pool 配置需要默认使用 `isSignup: true` 作为登录相关接口的默认参数
- Deprecate RussellError.LoginSession.userAlreadyExists. 已注册用户在使用 `isSignup: true` 参数时，不会再收到"该账户已注册"的错误信息了
- [迁移引导](Documents/MigrationTo4_0.md)

## [3.2.0] - 2019-06-20
### Added
- Russell 请求增加 X-B3-TraceID Headers
- URLConfiguration 增加 usesHTTPDNS 选项

## [3.1.0] - 2019-06-13
### Fixed
- 修复请求被意外 cancel 时没有回调的问题

### Changed
- 强制所有 Russell 请求不使用 URLCache

## [3.0.9] - 2019-05-07
### Fixed
- 修复文案错误

## [3.0.8] - 2019-05-05
### Changed
- 迁移到 Swift 5.0

## [2.0.9] - 2019-05-05
### Added
- 账号/密码登录
- 邮箱验证码注册
- 设定/重设密码
- 第三方账号绑定
- 手机号绑定
- 401/403 状态码处理插件

### Changed
- 网络库替换成 Quicksilver
- 验证码相关 API 更新

## [1.1.7] - 2019-04-08
### Fixed
- 修复 `Token` 编解码问题
- 修复重发验证码的逻辑错误
- 修复 `User` 的解码问题

## [1.1.0] - 2019-02-20
### Changed
- 更新日志注入 APIs
- 更新错误码映射

## [1.0.0] - 2019-01-18
### Added
- 支持短信验证码注册/登录
- 支持第三方账号注册/登录
