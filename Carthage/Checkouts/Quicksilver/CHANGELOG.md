# Changelog

## [Unreleased]

## [3.3.0] - 2019-09-12
### Changed
- 支持 Xcode 11 & Swift 5.1

## [3.2.0] - 2019-09-04
### Added
- `QuiciksilverProvider` 对外暴露了当前 `QuicksilverURLSessionConfiguration` 的属性。(只读)
- `QuicksilverURLSessionConfiguration` 的 `useHTTPDNS` 变成了 `var`，支持后续修改。

## [3.1.0] - 2019-08-22
### Added
- 增加了对单个请求支持设置 timeout 的功能

## [3.0.0] - 2019-04-02
### Added
- 支持 Swift 5.0 & Xcode 10.2

### Changed
- 移除了自定的 Result 结构，使用 Swift 5.0 中提供的 Result
- 移除了之前标记为 warning 的两个废弃 API (func dowload 和 Notification.Name.reachabilityChanged)

## [2.1.3] - 2019-03-20
### Fixed
- Fix missing requires module StarstreamPrivate

## [2.1.2] - 2019-03-13
### Fixed
- 修复了 QuicksilverTask 在取消任务后获取 isRunning 状态出错的问题

## [2.1.1] - 2019-03-05
### Added
- 增加了一个 WebSocket 下新的 public API: isConnected, 用于获取 WebSocket on connected status or not.

## [2.1] - 2019-01-28
### Added
- 增加了 WebSocket， 及 WebSocket 支持 HTTPDNS 的特性

### Changed
- 调整了 Response 及 QuicksilverError 的 Description， 提供更清晰的结果输出
- 升级 LingoHTTPDNS 到 2.2.2 https://git.llsapp.com/ios/lingo-http-dns/tags/2.2.2

## [2.0.4] - 2018-11-12
### Changed
- NetworkLoggerPlugin 请求错误日志优化 https://git.llsapp.com/client-infra/Quicksilver/issues/2
- typo fix https://git.llsapp.com/client-infra/Quicksilver/issues/1

## [2.0.3] - 2018-11-05 [YANKED]
### Fixed
- 修复了一个潜在的在多线程中操作 QuicksilverProvider 导致的 crash 问题。

## [2.0.1] - 2018-10-15
### Fixed
- 修复 Reachability init 初始化错误的问题。

## [2.0.1] - 2018-10-11
### Changed
- 移除了针对某一个 Request 对象做单独配置的接口。（错误的设计）

## [2.0.0] - 2018-09-27
### Added
- 支持 Xcode 10 & Swift 4.2
- 支持断点下载的相关 API，可以参考 Demo 完成
- 优化了相关的 API 实现
