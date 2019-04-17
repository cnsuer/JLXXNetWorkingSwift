//
//  ViewController.swift
//  JLXXNetWorkingSwift
//
//  Created by apple on 2019/4/17.
//  Copyright © 2019年 JLXX. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}
	
	@IBAction func login(_ sender: Any) {
		let api = JLXXLoginApi.getUserInfo
		JLXXNetWorking.shared.request(api, completion: { (jsonString) -> (Void) in
//			JLXXAccount.shared = JLXXAccount.deserialize(from: jsonString, designatedPath: "data")
		
			debugPrint(jsonString)
			
		}, failed: { (reason) -> (Void) in
			debugPrint(reason)
		})
	}
	
	@IBAction func getUserInfo() {
		let api = JLXXUserProfileApi.getUserInfo(user_id: "10000")
		JLXXNetWorking.shared.request(api, completion: { (jsonString) -> (Void) in
//			let model = JLXXUserProfileModel.deserialize(from: jsonString, designatedPath: "data")
			debugPrint(jsonString)
		}, failed: { (reason) -> (Void) in
			debugPrint(reason)
		})
	}

}

