# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [5.0.0] - 2019-09-12

### Changed
- 支持 Xcode 11 & Swift 5.1

### Removed
- 移除了对 LogXDestination 的支持

## [4.1.0] - 2019-09-12

### Changed
- 支持 Xcode 11 & Swift 5.1

## [4.0.0] - 2019-07-02

### Changed
- 调整了 `LingoLogPlugin` 的定义及实现，方便用于 Thanos 服务队日志信息的捕获。
- 修正了一些文档。

## [3.0.0] - 2019-04-28

### Fixed
- 当外部调用 `LoggerTool` 下 `uploadLog` 相关方法时会出现一定几率 Crash 的问题。 https://git.llsapp.com/ios/mcu/issues/15

### Removed
- 修正了 `LingoLogPlugin` 协议，删除了不必要的冗余接口。