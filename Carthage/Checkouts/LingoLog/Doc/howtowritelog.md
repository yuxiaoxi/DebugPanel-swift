## 如何打好一条日志

### 日志 `Tag` 的使用

1. 应当给每一个独立的模块设置单独的 `Tag`。如数据打点收集模块的日志输出，设置 `Tag` 为 `Tachikoma`, 比如论坛模块的日志输出, 设置 `Tag` 为 `ForumModule`。
2. 在一个大型的独立模块中，可以通过扩展 `Tag` 给不同业务输出自定义日志。比如在 `DarwinCourse` 这个大型独立模块中，可以给 `PT` 相关业务日志输出设置 `Tag` 为 `DarwinCourse.PT`。
3. 给需要在测试阶段获得的敏感信息设置单独的 `Tag`，以便在线上阶段过滤掉敏感信息日志的收集。

### 不同日志级别的使用指南

#### error 
`The most serious and highest priority log level. Use this only when your app has triggered a serious error.`

1) 影响到程序正常运行的异常情况。类似如下案例：

1. 打开配置文件失败 （eg: realm 初始化失败）
2. 第三方对接的异常 (eg: 使用微信支付，微信 SDK 一直抛出 error)
3. 所有`直接``block`到 `核心代码调用`的异常。`但是不应该包括业务异常`。

2) 不应该出现的情况:

1. 比如网络请求出错的返回结果使用 Error 级别的日志输出。(eg: 网络请求结果出错这个最终 case 可能由于用户网络原因或者别的其他原因导致，并不需要达到 Error 级别的日志输出)


3) 当你使用 Error 级别输出日志时，必须添加相关的上下文。

1. 比如，当从数据库通过 UserId 获取已经存在的 UserInfo 出错时。👍的日志输出应该为：`Logger.error("fetch user info with \(userId) failed from data, db error = \(error)")`。❌的日志输出为：`Logger.error("db error = \(error)")`。

4) 如果进行了抛出异常操作，请不要记录 error 日志，由最终处理方进行处理。

	❌
	func runCar() throws {
		do {
	   		try car.run()
		} catch {
			Logger.error("car: \(car) run on error. error = \(error)")
			throw error
		}
	}
	
	
#### warning
`Use this log level when reaching a condition that won’t necessarily cause a problem but strongly leads the app in that direction`

1) 不应该出现但是不影响程序正常运行的异常情况。类似如下案例：

 1. 有容错机制的时候出现的错误情况
 2. 找不到本应该存在的配置文件，但是系统能自动创建配置文件

2） 即将接近临界值的时候，例如：
	
 1. 设置的缓存值占用达到警告线

3) 业务异常的记录, 例如:
	
 1. 当接口抛出业务异常时，应该记录此异常。


#### info
`This is typically used for information useful in a more general support context. In other words, info that is useful for non developers looking into issues`

1） 系统运行信息。类似如下：

1. 客户端中一些 Service 服务中对于系统/业务状态的变更
2. 主要逻辑中的分步骤

2） 外部接口部分。类似如下:

1. 所有网络请求的参数等信息
2. 调用第三方的调用参数和调用结果

##### 说明

1. 并不是所有的 Service 都需要在入口和出口日志记录。一些简单的单一的 Service 是没有意义的。

 
 	   	❌
 	 
	 	func fetchTopicList() -> [Topic] {
	 	 Logger.info("start fetching topic list")
	 	 let db = DB.open()
	 	 let topics = db.fetch(type: Topic.self, conut: 10)
	 	 Logger.info("stop fetching topic list")
	 	 return topics
	 	}

2. 对于复杂的业务逻辑，需要进行关键路径的日志输出。比如 `Lingome` 项目中 IAP 的购买，或者订单创建, 订单状态变更等。
3. 跨模块调用时，应该记录入参和出参。比如 `Lingome` 项目中调用 `LingoModuleBridge` 中定义的接口时。

#### debug
`Use this level for printing variables and results that will help you fix a bug or solve a problem.`

1) 输出有助于帮助开发者解决问题的相关信息，必须带上相关参数。类似如下案例:
 
 1. 在程序中 `if else` 的逻辑分叉处
 2. 在重要方法的入口和出口
 3. 一些代码 comment 信息应该是用 debug 输出

      	❌
      
      	//1. 获取用户基本薪资

    	//2. 获取用户休假情况

    	//3. 计算用户应得薪资

	
		👍
		
		Logger.debug("获取用户基本薪资")
		
		Logger.debug("获取用户休假情况")

		Logger.debug("计算用户应得薪资")

#### verbose
`The lowest priority level. Use this one for contextual information.`

可以填写所有的想知道的相关信息(但不代表可以随便写，信息要有意义,最好有相关参数)


### 一些案例

#### 对外部的调用封装

程序中对外部系统与模块的依赖调用前后都记下日志，方便接口调试。出问题时也可以很快理清是哪块的问题。

	Logger.debug("calling external system: \(parameters)")
	var result: Object?
	do {
		result = callRemoteSystem(params)
		Logger.debug("called successfully. result is \(result)")
	} catch {
		Logger.warning("Failed at calling xxx system. exception: \(error)")
	}

#### 状态变化

程序中重要的状态信息的变化应该记录下来，方便查问题时还原现场，推断程序运行过程。

	var isRunning: Bool
	//...
	isRunning = true
	Logger.info("System is running")
	//...
	isRunning = false
	Logger.info("System was interrupted by \(something)")
	
#### 系统入口与出口

这个粒度可以是重要方法级或模块级。记录它的输入与输出，方便定位。

	  func execute(input: Object) {
		  Logger.debug("Invoke parames: \(input)")
		  var result: Object?
		  
		  // business logic
		  
		  Logger.debug("method result: \(result)")
	  }
	
#### 业务异常

任何业务异常都应该记下来。

	 do {
	 	// business logic
	 } catch let error = A {
		Logger.warning("description \(error)")
	 } catch let error = B {
	 	Logger.warning("description \(error)")
	 } catch error {
	 	Logger.error("description \(error)")
	 }
	
#### 非预期执行

为程序在“有可能”执行到的地方打印日志。如果我想删除一个文件，结果返回成功。但事实上，那个文件在你想删除之前就不存在了。最终结果是一致的，但程序得让我们知道这种情况，要查清为什么文件在删除之前就已经不存在。

	 let value: Int = 1
	 let absResult = abs(value)
	 if (absResult < 0) {
	 	Logger.info("origin int \(value) has nagetive abs \(absResult)")
	 }

#### 很少出现的else情况

else 可能吞掉你的代码，或是赋予难以理解的最终结果。

	var result: Object?
	
	if (running) {
		result = aaa
	} else {
		result = bbb
		Logger.debug("system does not running, we change the final result value to \(result)")
	}

#### 关键方法的执行时间

我们应当在一些关注性能的地方，输出关键行为的耗时。
	
	// business logic
	Logger.info("excution cost: \(time)")
	
### 一些错误的案例 ❌

#### 混淆信息的Log

日志应该是清晰准确的。

如下案例，当看到日志的时候，你知道是因为连接池取不到连接导致的问题么？

	let connection = ConnectionFactory.getConnection()
	if connection == nil {
		Logger.warning("System initialized unsuccessfully")
	}
	
#### 记错位置

产品代码中，使用系统相关方法记录日志，导致没有找到日志。

	printf("user logged with id = \(id)")
	
#### 记错级别

记错级别常常发生，常见的如：混淆代码错误和用户错误,如登录系统中，如果恶意登录，那系统内部会出现太多 warning，从而让开发者误以为是代码错误。可以反馈用户以错误，但是不要记录用户错误的行为，除非想达到控制的目的。

	Logger.error("failed login by username = \(username)")
	
#### 遗漏信息

日志少了上下文信息, 将会导致毫无参考价值。

 	do {
 	} catch {
 		Logger.warning(error)
 	}

#### 循环中

在一个循环计算中，一直输出对应的值。

如下案例：

	request.upload().progress { progress _
		Looger.debug("request upload progress = \(progress)")
	}