//
//  JLXXNetWorking.swift
//  JLXXNetWorkingSwift
//
//  Created by apple on 2019/4/15.
//  Copyright © 2019年 JLXX. All rights reserved.
//

import Foundation
import Moya

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


struct JLXXNetWorking {
	
	///先添加一个闭包用于成功时后台返回数据的回调
	typealias successClosure = ( (String) -> (Void))
	///失败的回调(返回失败数据,根据返回的数据,做不同的UI处理)
	typealias failedClosure = ( (String) -> (Void) )
	///错误的回调(返回失败原因,提示错误信息)
	typealias faultClosure = ( (String) -> (Void) )

	static let shared = JLXXNetWorking()
	
	private let provider = MoyaProvider(endpointClosure: myEndpointClosure, requestClosure: requestClosure, plugins: [networkPlugin], trackInflights: false)

	private init() { }
	
	/// 用一个方法封装provider.request()
	func request(_ api: JLXXApi, completion: @escaping successClosure, fault: faultClosure? = nil, failed: failedClosure? = nil ) {
		//先判断网络是否有链接 没有的话直接返回--代码略
		
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
						fault?(message)
						failed?(jsonString)
					}
				} catch {
					fault?("不是json数据")
					debugPrint("网络返回的数据转为字典失败!!!!!")
				}
			case let .failure(error):
				if let errorDescription = error.errorDescription {
					fault?(errorDescription)
					debugPrint("网络请求失败:\(errorDescription)")
				}else {
					//网络连接失败，提示用户
					debugPrint("网络连接失败")
				}
			}
		}
	}
}





