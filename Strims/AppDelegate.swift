//
//  AppDelegate.swift
//  Strims
//
//  Created by Zachary Clute on 12/11/14.
//  Copyright (c) 2014 Zachary Clute. All rights reserved.
//

import Cocoa

let STRIMURL = "twitch.tv/"
let COMMAND = "/usr/local/bin/livestreamer"
let QUALITY = "source"
let INTERVAL: NSTimeInterval = 10.0

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
	
	
    private var menuController: MenuController!
	private var strimsController: StrimsController!
	private var timer: NSTimer!
	private let backgroundQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		strimsController = StrimsController(strimURL: STRIMURL, command: COMMAND, quality: QUALITY)
        menuController = MenuController(strimsController)
		
        guard checkForLivestreamer() else {
            
        }
		//DO NOT DISPATCH THE TIMER, dispatch is done in timerevents
		timer = NSTimer.scheduledTimerWithTimeInterval(INTERVAL, target: self, selector: "timerEvents:", userInfo: nil, repeats: true)
	}
    
    func checkForLivestreamer() throws -> Bool {
        let task = NSTask()
        let pipe = NSPipe()
        var data: NSData
        var output: NSString
        
        task.launchPath = COMMAND
        task.standardOutput = pipe
        task.launch()
        
        data = pipe.fileHandleForReading.readDataToEndOfFile()
        output = NSString(data: data, encoding: NSUTF8StringEncoding)!
        
        guard output.containsString("usage") else {
            return false
        }

        return true
    }
	
    func timerEvents(sender: NSTimer) {
        //did streams change?
        dispatch_async(backgroundQueue, {
            let temp: Dictionary = self.strimsController.strimsList
            self.menuController.refresh()
            for (name, _) in temp {
                if (temp[name] != self.strimsController.strimsList[name]) {
                    let status: String = self.strimsController.strimsList[name]! ? "online" : "offline"
                    self.initNotify(name, status: status)
                }
            }
        })
    }
    
    func initNotify(name: String, status: String) {
        let notify: NSUserNotification = NSUserNotification()
        let center: NSUserNotificationCenter = NSUserNotificationCenter.defaultUserNotificationCenter()
        
        
        center.delegate = self as NSUserNotificationCenterDelegate
        notify.title = name
        notify.subtitle = "Is " + status
        notify.soundName = NSUserNotificationDefaultSoundName
        notify.deliveryDate = NSDate(timeIntervalSinceNow: 0)
        if(menuController.notificationsAreOn == true) {center.scheduleNotification(notify);}
    }
    
    func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }

	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}
	
	
}