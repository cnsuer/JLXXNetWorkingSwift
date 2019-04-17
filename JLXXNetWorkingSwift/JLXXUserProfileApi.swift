//
//  JLXXUserProfileApi.swift
//  JLXXNetWorkingSwift
//
//  Created by apple on 2018/12/11.
//  Copyright © 2019年 JLXX. All rights reserved.
//

import Foundation
import Moya

enum JLXXUserProfileApi {
	
	enum MomentType: Int {
//		类型：0所有动态，1他人动态（需要user_id）,2自己动态，3获取我关注人的动态，4获取推荐动态
		case all
		case others
		case `self`
		case follow
		case recommend
	}
	
	enum MatchingType: Int {
		case system = 1
		case distance = 2
	}
	
	case matchingFriend(type: MatchingType)
	case getUserInfo(user_id: String)
	case getUserMoment(type: MomentType, user_id: String?, limit_begin: Int)
	case getUserComments(moment_id: Int, limit_begin: Int)
	case publishUserMoment(content: String?, position: String?, longitude: String?, latitude: String?, audio: String?, images: [String])
	case comment(moment_id: Int, content: String)
}

extension JLXXUserProfileApi: JLXXApi {
	var path: String {
		switch self {
		case .getUserInfo:
			return "user/relationship/userInfo"
		case .getUserMoment:
			return "user/moment/getMoment"
		case .getUserComments:
			return "user/momentComments/getComments"
		case .comment:
			return "user/momentComments/setComments"
		case .publishUserMoment:
			return "user/moment/setMoment"
		case .matchingFriend:
			return "user/relationship/friend"
		}
	}
	
	var task: Moya.Task {
		switch self {
		case .getUserInfo(let user_id):
			let urlParameters: [String: Any] = ["user_id": user_id]
			return .requestParameters(parameters: urlParameters, encoding: URLEncoding.default)
		case let .getUserMoment(type, user_id, limit_begin):
			var urlParameters: [String: Any] = ["type": type.rawValue,
												"limit_begin": limit_begin,
												"limit_num": 20]
			if  type == .others, let uid = user_id {
				urlParameters["user_id"] = uid
			}
			return .requestParameters(parameters: urlParameters, encoding: URLEncoding.default)
		case .getUserComments(let moment_id, let limit_begin):
			let urlParameters: [String: Any] = ["moment_id": moment_id,
												"limit_begin": limit_begin,
												"limit_num": 20]
			return .requestParameters(parameters: urlParameters, encoding: URLEncoding.default)
		case .comment(let moment_id, let content):
			let urlParameters: [String: Any] = ["moment_id": moment_id,
												"content": content]
			return .requestParameters(parameters: urlParameters, encoding: URLEncoding.default)
		case .publishUserMoment(let content, let position, let longitude, let latitude, let audio, let images):
			let urlParameters: [String: Any] = ["content": content ?? "",
												"position": position ?? "",
												"longitude": longitude ?? "",
												"latitude": latitude ?? "",
												"audio": audio ?? "",
												"image": images]
			return .requestParameters(parameters: urlParameters, encoding: URLEncoding.default)
		case .matchingFriend(let type):
			let urlParameters: [String: Any] = ["type": type.rawValue,
												"limit_begin": 0,
												"limit_num": 20]
			return .requestParameters(parameters: urlParameters, encoding: URLEncoding.default)
		}
	}
}
