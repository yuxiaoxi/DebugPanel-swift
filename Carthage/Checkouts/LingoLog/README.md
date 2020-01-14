## LingoLog

### 简介

提供给 iOS/macOS 项目使用的日志模块。

### Installation

#### Carthage

	git git@git.llsapp.com:ios/LingoLog.git

### Requirements

最低运行版本：iOS 10.0

编译语言版本：Swift 5.1

IDE版本：Xcode 11.0

### 接入

1. 客户端接入异常简单，请直接参考工程头文件 API 描述和 Demo 工程

#### 接入 AirLogs

AirLogs Mac App 可以通过有线及无线方式连接使用 LingoLog - LiveLog Output 的移动设备, 在 macOS App 上实时查看客户端输出的 Log, 具有格式化显示 Log 信息、Log Level 与 Tag 过滤、自定义 Log Formatter 与 Filter、保存到数据库以及导出历史日志文件等功能.

##### 如何在客户端上启用 AirLogs

启用 AirLogs 非常简单. 与给 LingoLog 添加其他 Log Output 相同, 仅需要在配置 LingoLog 服务时加上 LiveLogOutput 即可.

```
LoggerTool.appendLiveLogOutput(filterRule: )
```

启动 AirLogs Mac 端, AirLogs 会自动启动 PeerTalk USB 与 Multipeer Connectivity 无线连接服务。连接设备 (模拟器也可使用),后即会自动显示日志面板.
请注意, LiveLog 应该只在 Debug 与 QA Testing 等环境下使用, 不应发布到线上环境。

关与 AirLogs 的介绍：[https://git.llsapp.com/roc.zhang/AirLogs/](https://git.llsapp.com/roc.zhang/AirLogs/)

##### 如何获取到 AirLogs Mac App

可以在 AirLogs Repo Tags 的 attachment 里下载到最新版本的 AirLogs Mac App.

[https://git.llsapp.com/roc.zhang/AirLogs/tags](https://git.llsapp.com/roc.zhang/AirLogs/tags)

### Q&A

Q: 如何在日志中捕获 crash 相关信息？有什么需要注意的？

A: 在 App 启动的 didFinishLaunching 的方法中进行 `configCrashCapture` 即可把 crash 相关信息写入到日志系统中。 捕获 Crash 涉及到信号传递，当有多个收集 Crash 框架共同接入时，需要考虑到公用问题。目前经过测试 LingoLog 中的 Crash 捕获能够正常和 Crashlytics 同时工作。

Q: Release 下 crash 的日志堆栈会被解析吗？

A: 不会，Release 下仅仅作为一个参考，可以和 Crashlytics 配合一起使用。

### 如何打好一条日志

[参考文档](./Doc/howtowritelog.md)