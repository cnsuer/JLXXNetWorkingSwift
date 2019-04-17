//
//  JLXXApi.swift
//  JLXXNetWorkingSwift
//
//  Created by apple on 2019/4/15.
//  Copyright © 2019年 JLXX. All rights reserved.
//

import Foundation
import Moya

//这里可以添加想要的扩展
protocol JLXXApi {
	var url: String { get }
	var path: String { get }
	var task: Moya.Task { get }
	var requestTimeOut: Double { get }
}

extension JLXXApi {
	
	var url: String {
		return JLXXNetWorkingBaseApi
	}
	
	var requestTimeOut: Double {
		return 30.0
	}
	
}

class JLXXBridgeTarget {
	
	var api: JLXXApi
	
	init(api: JLXXApi) {
		self.api = api
	}
	
	deinit {
		print("哈哈哈哈,我over了,你呢?")
	}
}

extension JLXXBridgeTarget: TargetType {
	
	var baseURL: URL {
		return URL.init(string: api.url)!
	}
	
	var path: String {
		return api.path
	}
	
	var method: Moya.Method {
		return .post
	}
	
	var sampleData: Data {
		return "".data(using: String.Encoding.utf8)!
	}
	
	var task: Task {
		return api.task
	}
	
	var headers: [String : String]? {
		return ["XX-Api-Version": "1.1.1",
		 "XX-Device-Type": "iphone",
		 "lang": "zh-cn"
		]
	}
	
}
