//
//  StrimsController.swift
//  Strims
//
//  Created by Zachary Clute on 12/12/14.
//  Copyright (c) 2014 Zachary Clute. All rights reserved.
//

import Foundation

class StrimsController {
	private let strimURL: String
	private let command: String
	private let quality: String
    private let strimsDefaultList: [String: AnyObject]
	private let qualityOfServiceClass: qos_class_t
	private let backgroundQueue: dispatch_queue_t
    private let userDefaultObject: NSUserDefaults
    
    private(set) var strimsList: [String: Bool]!
	
	init(strimURL: String, command: String, quality: String) {
		qualityOfServiceClass = QOS_CLASS_BACKGROUND
		backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        userDefaultObject = NSUserDefaults.init()
        strimsList = [String: Bool]()
        
		self.strimURL = strimURL
		self.command = command
		self.quality = quality
        
        if userDefaultObject.persistentDomainForName(NSBundle.mainBundle().bundleIdentifier!) != nil {
            strimsDefaultList = (userDefaultObject.persistentDomainForName(NSBundle.mainBundle().bundleIdentifier!))!
            
            for (name, _): (String, AnyObject) in strimsDefaultList {
                self.strimsList[name] = false
            }
            paraScan(self.strimsList)
        }
        else {
            strimsDefaultList = [String: AnyObject]()
        }
	}
	
	//function to asyncly run Scan on each stream name
	func paraScan(strims: [String: Bool]) {
		let group: dispatch_group_t = dispatch_group_create()
		for (name, _) in strims {
			dispatch_group_async(group, backgroundQueue, {
				self.strimsList[name.lowercaseString] = self.scan(name)
			})
		}
		dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
	}
	
	func removeStrim(name: String) {
		assert(strimsList[name] != nil)
		if let _ = strimsList.removeValueForKey(name) {
			rewriteList()
		}
	}
	
	func addStrim(name: String) {
		if name != " " && name != "" {
			strimsList[name.lowercaseString] = false
			rewriteList()
		}
	}
	
	func rewriteList() {
        userDefaultObject.setPersistentDomain(strimsList, forName: NSBundle.mainBundle().bundleIdentifier!)
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