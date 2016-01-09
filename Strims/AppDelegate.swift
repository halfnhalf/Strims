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
    
	private var strimsController: StrimsController!
	private var timer: NSTimer!
	private var didWeInstallTimer: NSTimer!
	private let backgroundQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
    @IBOutlet weak var installController: InstallController!
    @IBOutlet weak var menuController: MenuController!
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
       /* while try installController.checkForLivestreamer() {
            setup()
        }
        catch InstallController.InstallError.NotInstalled {
            installController.askToInstallLivestreamer()
        } catch {}*/
        
        do {
            try installController.checkForLivestreamer()
            setup()
        } catch InstallController.InstallError.NotInstalled {
            installController.askToInstallLivestreamer()
            didWeInstallTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "shouldWeProceed:", userInfo: nil, repeats: true)
        } catch {}
        
		
		//DO NOT DISPATCH THE TIMER, dispatch is done in timerevents
	}
    
    func shouldWeProceed(sender: NSTimer) {
        if installController.isInstalled {
            didWeInstallTimer.invalidate()
            didWeInstallTimer = nil
            setup()
        }
        if !installController.installWindow.visible {
            NSApplication.sharedApplication().terminate(self)
        }
    }
    
    func setup() {
		strimsController = StrimsController(strimURL: STRIMURL, command: COMMAND, quality: QUALITY)
        menuController.setup(strimsController)
		timer = NSTimer.scheduledTimerWithTimeInterval(INTERVAL, target: self, selector: "timerEvents:", userInfo: nil, repeats: true)
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