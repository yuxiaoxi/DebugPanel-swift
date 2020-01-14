## Introduction

App 统一debug面板调试器 iOS 客户端接入方案。
效果如下图：

![](Debug.png?raw=true "Example PNG")

![](DEMO_EXAMPLE.PNG?raw=true "Example PNG")
![](demo.PNG?raw=true "Example PNG")

## Features

业务App提供可灵活配置的debug面板，既包括基础的功能：扫一扫、性能悬浮窗、一键切换环境等功能，也可以根据业务app的属性进行面板扩展和定制


## Requirements

最低运行版本：iOS 10.0  
编译语言版本：Swift 4.2.1

## How to Use

### init

``` swift
let debugBar = LLSDebugBar.startDebugPanel(true)
```
### Setup 必须的设置

有两种注册panel的方式：

1. 通过回调block方式
2. 通过扩展protocol方式

第一种通过回调方式的示例如下：

``` swift
// MARK: debugpanel register by block
extension AppDelegate {
  
  func debugConfigurationByBlock() {
    let debugBar = LLSDebugBar.startDebugPanel(true)
    
    debugBar?.addExtentsionButton("test1", buttonStyle: DebugBarButtonStyle.ROWHASTWO) {
      print("----test1")
    }
    debugBar?.addExtentsionButton("test", buttonStyle: DebugBarButtonStyle.ROWHASTWO) {
      print("----test")
    }
    debugBar?.addExtentsionButton("test2", buttonStyle: DebugBarButtonStyle.ROWHASONE) {
      print("----test2")
    }
    debugBar?.configCommonOperattion(.oneKeyProduct) {
      print("----onekeyproduct")
    }
    debugBar?.configCommonOperattion(.oneKeyStaging) {
      print("----onekeystaging")
    }
    debugBar?.openURLByRouter(.routerURL) { urlStr in
      print("----openURLByRouter", urlStr)
    }
    debugBar?.configCommonOperattion(.openDebugPanel) {
      print("----openDebugPanel")
    }
  }
}
```

第二种通过protocol方式示例：

``` swift
// MARK: debugpanel register by protocol
extension AppDelegate: LLSDebugProtocol {
   
   func debugConfigurationByProtocol() {
      let debugBar = LLSDebugBar.startDebugPanel(true)
      
      debugBar?.addExtentsionButton("test1", buttonStyle: DebugBarButtonStyle.ROWHASTWO) {
         print("----test1")
      }
      debugBar?.addExtentsionButton("test", buttonStyle: DebugBarButtonStyle.ROWHASTWO) {
         print("----test")
      }
      debugBar?.addExtentsionButton("test2", buttonStyle: DebugBarButtonStyle.ROWHASONE) {
         print("----test2")
      }
      debugBar?.debugDelegate = self
   }
   
   func oneKeyProduct() {
      print("----onekeyproduct")
   }
   
   func oneKeyStaging() {
      print("----onekeystaging")
   }
   
   func openURLByRouter(_ urlStr: String) {
      print("----openURLByRouter", urlStr)
   }
   
   func openDebugPanel() {
      print("----openDebugPanel")
   }
}
```

### How to extension

在面板中添加新的定制按钮
定制按钮有两型类型：
``` swift
public enum DebugBarButtonStyle: Int {
  case ROWHASONE = 1 // 一行有只有一个button
  case ROWHASTWO = 2 // 一行有两个button
}
```

添加定制按钮示例：
``` swift
debugBar?.addExtentsionButton("test1", buttonStyle: DebugBarButtonStyle.ROWHASTWO) {
    print("----test1")
}
```
注意：button的title不能重复，否则会影响点击事件的触发

