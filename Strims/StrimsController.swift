//
//  StrimsController.swift
//  Strims
//
//  Created by Zachary Clute on 12/12/14.
//  Copyright (c) 2014 Zachary Clute. All rights reserved.
//

import Foundation

class StrimsController {
	var strims: Dictionary<String, Bool> = [:]
	private let strimURL: String
	private let command: String
	private let quality: String
	private let configPath: String
	private let qualityOfServiceClass: qos_class_t
	private let backgroundQueue: dispatch_queue_t
	
	init(strimURL: String, command: String, quality: String) {
		qualityOfServiceClass = QOS_CLASS_BACKGROUND
		backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
		
		self.strimURL = strimURL
		self.command = command
		self.quality = quality
		
		//create a native dictionary from plist. Currently swift has no way to read plist natively
		//so this is a weird workaround
		if let path = NSBundle.mainBundle().pathForResource("config", ofType: "plist") {
			self.configPath = path
			if let strims = NSDictionary(contentsOfFile: path) as? Dictionary<String, Bool> {
				for (name, _): (String, Bool) in strims {
					self.strims[name] = false
				}
			}
		}
        else {
            self.configPath = String()
        }
		paraScan(self.strims)
	}
	
	//function to asyncly run Scan on each stream name
	func paraScan(strims: [String: Bool]) {
		let group: dispatch_group_t = dispatch_group_create()
		for (name, _) in strims {
			dispatch_group_async(group, backgroundQueue, {
				self.strims[name.lowercaseString] = self.scan(name)
			})
		}
		dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
	}
	
	func removeStrim(name: String) {
		assert(strims[name] != nil)
		if let _ = strims.removeValueForKey(name) {
			rewriteList()
		}
	}
	
	func addStrim(name: String) {
		if name != " " && name != "" {
			strims[name.lowercaseString] = false
			rewriteList()
		}
	}
	
	func rewriteList() {
		let dict = strims as NSDictionary
		
		dict.writeToFile(configPath, atomically: true)
	}
	
	func scan(strim: String) -> Bool {
        // Maybe we should use the twitch api instead of launching a task. This whould save time perhaps?
        //
		let task = NSTask()
		let pipe = NSPipe()
		var data: NSData
		var output: NSString
		
		task.launchPath = command
		task.arguments = ["-j", strimURL + strim, quality]
		task.standardOutput = pipe
		task.launch()
		
		data = pipe.fileHandleForReading.readDataToEndOfFile()
		output = NSString(data: data, encoding: NSUTF8StringEncoding)!
		//print(output)
		
		if output.containsString("error") {return false}
		return true
	}
	
	func initStrim(strim: String) {
		let task = NSTask()
		let pipe = NSPipe()
		var data: NSData
		var output: NSString
		
		task.launchPath = command
		task.arguments = [strimURL + strim, quality]
		task.standardOutput = pipe
		task.launch()
		
		data = pipe.fileHandleForReading.readDataToEndOfFile()
		output = NSString(data: data, encoding: NSUTF8StringEncoding)!
		//print(output)
	}
}