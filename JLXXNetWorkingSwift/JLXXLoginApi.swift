//
//  JLXXLoginApi.swift
//  JinglanIM
//
//  Created by apple on 2018/12/10.
//  Copyright © 2019年 JLXX. All rights reserved.
//

import Foundation
import Moya

enum JLXXLoginApi {
	case login(username: String, password: String)
	case register(phone: String?, password: String?, nickname: String?, birthday: String, sex: Int, countryId: Int, avatar: Data)
	case getUserInfo
	case countryList
}


//type

//user_nickname
//
//参数值
//avatar
//
//参数值
//location
//
//参数值
//longitude
//
//参数值
//latitude
//
//参数值
//text_introduces
//
//参数值
//voice_introduces_file_url
//
//参数值


extension JLXXLoginApi: JLXXApi {
	
	var path: String {
		switch self {
		case .login:
			return "user/public/login"
		case .register:
			return "user/public/register"
		case .countryList:
			return "user/main/countryList"
		case .getUserInfo:
			return "user/profile/userInfo"
		}
	}
	
	var task: Task {
		switch self {
		case let .login(username, password):
			let urlParameters: [String: Any] = ["username": username,
											   "password": password]
			return .requestParameters(parameters: urlParameters, encoding: URLEncoding.default)
		case let .register(phone, password, nickname, birthday, sex, countryId, avatar):
			//后台的content-Type 为application/x-www-form-urlencoded时选择URLEncoding
			let urlParameters:[String: Any] = ["username": phone ?? "",
											   "password": password ?? "",
											   "user_nickname": nickname ?? "",
											   "birthday": birthday,
											   "sex": sex,
											   "country_id": countryId]
			let formData = MultipartFormData(provider: .data(avatar), name: "avatar", fileName: "avatar.png", mimeType: "image/png")
			return .uploadCompositeMultipart([formData], urlParameters: urlParameters)
		case .getUserInfo:
			return .requestParameters(parameters: ["type": 0], encoding: URLEncoding.default)
		default:
			return .requestPlain
		}
	}
}
