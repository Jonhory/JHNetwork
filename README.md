# Swift4.1网络层封装

## 导航
* [介绍](#介绍)
* [TODO](#TODO)
* [快速接入](#快速接入)
* [代码示例](#代码示例)

## <a id="介绍"></a> 介绍:
* 使用Swift4.1，基于[Alamofire4.0+](https://github.com/Alamofire/Alamofire)、[SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)封装的网络中间层，提供快速缓存策略，帮助日常开发。
* 实现了GET／POST请求JSON数据，可定义每一个请求是否缓存成功的回调数据。
* 利用请求的url拼接传入的参数字典，形成唯一性的字符串，经过MD5加密后保存至`Library/Caches/JHNetworkCaches`文件夹，该路径可自行修改。
* 当调用一个请求方法时，会经过以下逻辑判断处理：

	1. 判断`shoulObtainLocalWhenUnconnected`(网络异常时是否返回缓存数据)
	2. 判断当前`networkStatus`(当前网络状态)为`unknown`或`notReachable`
	3. 同时满足1、2点，尝试获取缓存，若有缓存，则返回**成功**的回调 
	4. 判断`refreshCache`(是否刷新缓存)
	5. 若第5点为否，则尝试获取缓存，若有缓存，则返回**成功**的回调
	6. 正式开始发起网络请求
	7. 成功回调的处理，利用`SwiftyJSON`解析
		* 如果`refreshCache`(是否刷新缓存)且`isCache`(是否缓存),则缓存回调数据
		* 返回**成功**的回调
		
	8. 失败回调的处理
		* 如果`error.code < 0` 且 `isCache`,尝试获取缓存，若有缓存，则返回**成功**的回调
		* 返回**失败**的回调


## <a id="快速接入"></a>快速接入:
* 将`JHNetwork.swift`拖入项目中
* `pod`导入
	
```
pod 'Alamofire', '~> 4.3'
pod 'SwiftyJSON', '~> 3.1.4'  
```

* 在项目的Build Settings里配置Swift Compiler - Custom Flags，展开Other Swift Flags，在Debug右侧输入`-D DEBUG`

## <a id="代码示例"></a>代码示例:
* 如果想在网络状态异常时返回缓存数据，可以在`AppDelegate.swift`中设置

```
JHNetwork.shared.shoulObtainLocalWhenUnconnected(shouldObtain: true)
```

* GET请求，默认缓存

```
//刷新缓存
getForJSON(url:finished:)
//可带参数，刷新缓存
getForJSON(url:parameters:finished:)
//可设置是否刷新缓存
getForJSON(url:refreshCache:parameters:finished:)
```

* GET请求，默认不缓存

```
getNoCacheForJSON(url:finished:)
getNoCacheForJSON(url:parameters:finished:)
getNoCacheForJSON(url:refreshCache:parameters:finished:)
```

* POST请求，默认缓存

```
postForJSON(url:finished:)
postForJSON(url:parameters:finished:)
postForJSON(url:refreshCache:parameters:finished:)
```

* POST请求，默认不缓存

```
postNoCacheForJSON(url:finished:)
postNoCacheForJSON(url:parameters:finished:)
postNoCacheForJSON(url:refreshCache:parameters:finished:)
```

* 最底层的请求方法

```
/// 请求JSON数据最底层
///
/// - Parameters:
///   - methodType: GET/POST
///   - urlStr: 接口
///   - refreshCache: 是否刷新缓存,如果为false则返回缓存
///   - isCache: 是否缓存
///   - parameters: 参数字典
///   - finished: 回调
requestJSON(methodType:urlStr:refreshCache:isCache:parameters:finished:)

```

* 上传图片数组

```
/// 上传图片数组
///
/// - Parameters:
///   - par: key是 images ，value是 UIImage
///   - urlStr: 上传路径
///   - finished: 回调
upload(par: [String: Any] , urlStr: String, finished: @escaping networkJSON)
```

* 每个请求都返回`Cancellable?`,可调用`cancel()`方法取消该请求

* 尝试获取指定url和参数的缓存

```
getCacheForJSON(url:parameters:finished:)
```

* 获取当前网络数据缓存字节数

```
totalCacheSize()
```

* 清除缓存

```
clearCaches()
```

## 灵感
* 灵感来自于[HYBNetworking](https://github.com/CoderJackyHuang/HYBNetworking)。

## 联系我
* 如果在使用过程中遇到问题，或者想要与我分享，吐槽我 <jonhory@163.com>

## License
* JHNetwork is released under the MIT license. See LICENSE for details.
