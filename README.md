
# JLXXNetWorkingSwift

### 参考自[MoyaNetworkTool](https://www.jianshu.com/p/adee88ddcd06)

#### **目录结构有所更改**

![image](https://restver.me/assets/images/networking-swift/menu.jpg)

大致可将网络框架拆分成

***JLXXNetworking.swift*** ---基本框架配置及封装写到这里

***JLXXNetworkingConfig.swift*** ---这个其实可有可无

***JLXXApi.swift*** ---主要修改的就是这个文件,本来这里写的是一个API的枚举，枚举值是接口名,然后 extension 遵守 TargetType 协议,但是有一个问题就是这样,会导致这个文件极度膨胀,两人同时修改的话,必然会出现冲突,所以这里建一个中间类,遵守 TargetType 协议,然后自定义一个协议,提供所需要的数据。

***定义协议***
```swift
protocol JLXXApi {
    var url: String { get }
    var path: String { get }
    var task: Moya.Task { get }
    var requestTimeOut: Double { get }
}
```

***提供默认实现***

```swift
extension JLXXApi {

    var url: String {
        return JLXXNetWorkingBaseApi
    }

    var requestTimeOut: Double {
        return 30.0
    }

}
```

***使用***

```swift
enum JLXXLoginApi {
    case login(username: String, password: String)
    case getUserInfo
    case countryList
}

extension JLXXLoginApi: JLXXApi {

    var path: String {
        switch self {
        case .login:
            return "user/public/login"
        case .countryList:
            return "user/main/countryList"
        case .getUserInfo:
            return "user/profile/userInfo"
        }
    }

    var task: Task {
        switch self {
        case let .login(username, password):
            let urlParameters: [String: Any] = ["username": username, "password": password]
            return .requestParameters(parameters: urlParameters, encoding: URLEncoding.default)
        case .getUserInfo:
            return .requestParameters(parameters: ["type": 0], encoding: URLEncoding.default)
        default:
            return .requestPlain
        }
    }
}
```

***JLXXNetworking.swift***

    1.后台返回错误的时候统一把error msg显示给用户

    2.只有返回正确或需要失败数据的时候才把数据提取出来进行解析

结果如下

```swift
/// 超时时长
private var requestTimeOut: Double = 30

/// endpointClosure用来构建Endpoint
private let myEndpointClosure = { (target: JLXXBridgeTarget) -> Endpoint in
	///这里的endpointClosure和网上其他实现有些不太一样。
	///主要是为了解决URL带有？无法请求正确的链接地址的bug
	let url = target.baseURL.absoluteString + target.path
	
	var endpoint = Endpoint(
		url: url,
		sampleResponseClosure: { .networkResponse(200, target.sampleData) },
		method: target.method,
		task: target.task,
		httpHeaderFields: target.headers
	)
	
	requestTimeOut = target.api.requestTimeOut //按照项目需求针对单个API设置不同的超时时长
	
	return endpoint
}

/// requestClosure用来构建URLRequest
private let requestClosure = { (endpoint: Endpoint, closure: MoyaProvider.RequestResultClosure) in
	do {
		var request = try endpoint.urlRequest()
		//设置请求时长
		request.timeoutInterval = requestTimeOut
		// 打印请求参数
		if let requestData = request.httpBody {
			print("\(request.url!)"+"\n"+"\(request.httpMethod ?? "")"+"发送参数"+"\(String(data: request.httpBody!, encoding: String.Encoding.utf8) ?? "")")
		}else{
			print("\(request.url!)"+"\(String(describing: request.httpMethod))")
		}
		closure(.success(request))
	} catch {
		closure(.failure(MoyaError.underlying(error, nil)))
	}
}

/*   设置ssl
let policies: [String: ServerTrustPolicy] = [
"example.com": .pinPublicKeys(
publicKeys: ServerTrustPolicy.publicKeysInBundle(),
validateCertificateChain: true,
validateHost: true
)
]
*/

// 用Moya默认的Manager还是Alamofire的Manager看实际需求。HTTPS就要手动实现Manager了
//private public func defaultAlamofireManager() -> Manager {
//    
//    let configuration = URLSessionConfiguration.default
//    
//    configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
//    
//    let policies: [String: ServerTrustPolicy] = [
//        "ap.grtstar.cn": .disableEvaluation
//    ]
//    let manager = Alamofire.SessionManager(configuration: configuration,serverTrustPolicyManager: ServerTrustPolicyManager(policies: policies))
//    
//    manager.startRequestsImmediately = false
//    
//    return manager
//}

/// NetworkActivityPlugin插件用来监听网络请求
private let networkPlugin = NetworkActivityPlugin.init { (changeType, targetType) in
	
	debugPrint("networkPlugin \(changeType)")
	//targetType 是当前请求的基本信息
	switch(changeType){
	case .began:
		print("开始请求网络")
		
	case .ended:
		print("结束")
	}
}

// https://github.com/Moya/Moya/blob/master/docs/Providers.md  参数使用说明
//stubClosure   用来延时发送网络请求


struct JLXXNetWorking {
	
	///先添加一个闭包用于成功时后台返回数据的回调
	typealias successClosure = ( (String) -> (Void))
	///失败的回调
	typealias failedClosure = ( (String) -> (Void) )
	///网络错误的回调
	typealias failedResponseClosure = ( (String) -> (Void) )

	static let shared = JLXXNetWorking()
	
	private let provider = MoyaProvider(endpointClosure: myEndpointClosure, requestClosure: requestClosure, plugins: [networkPlugin], trackInflights: false)

	private init() { }
	
	/// 用一个方法封装provider.request()
	func request(_ api: JLXXApi, completion: @escaping successClosure, failed: failedClosure? = nil, failedResponse: failedResponseClosure? = nil ) {
		
		let target = JLXXBridgeTarget(api: api)

		provider.request(target) { (result) in
			switch result {
			case let .success(response):
				do {
					//转JSON
					let responseObject = try JSONSerialization.jsonObject(with: response.data)
					guard let dic = responseObject as? Dictionary<String, Any>, let jsonString = String(data: response.data, encoding: String.Encoding.utf8) else {
						debugPrint("什么情况?不是json数据?????")
						return
					}
//					debugPrint("网络请求数据:\(dic)")
					if let code = dic[JLXXNetWorkingResCodeKey] as? Int, code == JLXXNetWorkingSuccessCode {
						completion(jsonString)
					}else {
						let message = dic[JLXXNetWorkingResMessageKey] as? String ?? "服务器返回数据错误"
						failed?(message)
						failedResponse?(jsonString)
					}
				} catch {
					failed?("不是json数据")
					debugPrint("网络返回的数据转为字典失败!!!!!")
				}
			case let .failure(error):
				if let errorDescription = error.errorDescription {
					failed?(errorDescription)
					debugPrint("网络请求失败:\(errorDescription)")
				}else {
					//网络连接失败，提示用户
					debugPrint("网络连接失败")
				}
			}
		}
	}
}

```

***JLXXNetWorkingConfig.swift*** --- 这个就是放一些公用字符串

```swift

/// 基础Api
let JLXXNetWorkingBaseApi = "http://deerlive.com/api/"

// 定义返回的JSON数据字段的key
/// 响应数据状态码的key
let JLXXNetWorkingResCodeKey = "code"
/// 响应数据成功的状态码
let JLXXNetWorkingSuccessCode = 1

/// 响应数据消息提示的key
let JLXXNetWorkingResMessageKey = "msg"

```

***这个时候我们再去用封装好的网络工具优雅的进行网络请求***

```swift
let api = JLXXLoginApi.getUserInfo

JLXXNetWorking.shared.request(api, success: { (jsonString) -> (Void) in
//用HandyJSON对返回的数据进行处理
// JLXXAccount.shared = JLXXAccount.deserialize(from: jsonString, designatedPath: "data")
    debugPrint(jsonString)
}, fault: { (reason) -> (Void) in
    debugPrint(reason)
})

```