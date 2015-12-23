//
//  MenuController.swift
//  Strims
//
//  Created by Zachary Clute on 12/23/15.
//  Copyright © 2015 Zachary Clute. All rights reserved.
//

import Foundation
import Cocoa

class MenuController {
    
    
    func setupMenuItems() {
        let icon = NSImage(named: "menuIcon")
        let textFieldMenu = NSMenu()
        let textFieldMenuItem =  NSMenuItem(title: "textField", action: nil, keyEquivalent: "")
        
        notificationsAreOn = true
        
        mainMenuButton =  NSStatusBar.systemStatusBar().statusItemWithLength(-1)
        mainMenu.autoenablesItems = false
        mainMenuButton.image = icon
        mainMenuButton.menu = mainMenu
        
        textFieldMenu.addItem(textFieldMenuItem)
        mainMenu.update()
    }
    
    //populate the list of streams and their status
    func populateStreamMenuItems() {
        for (name, online) in strimsController.strimsList {
            let (newItem, deleteMenu): (NSMenuItem, NSMenu) = nameMenuItem(name: name, online: online)[]
            
            newItem.target = self
            deleteMenu.itemAtIndex(0)!.target = self
            
            mainMenu.addItem(newItem)
            mainMenu.setSubmenu(deleteMenu, forItem: newItem)
        }
    }
    
    func refreshMenuItem(name: String) {
        //IF WE MAKE IT HERE ALL STRIMCONTROLLER MUST BE DEFINED UP TO REALTIME
        if mainMenu.itemWithTitle(name) == nil {
            let (newItem, deleteMenu): (NSMenuItem, NSMenu) = nameMenuItem(name: name, online: strimsController.strimsList[name]!)[]
            
            newItem.target = self
            deleteMenu.itemAtIndex(0)!.target = self
            
            mainMenu.addItem(newItem)
            mainMenu.setSubmenu(deleteMenu, forItem: newItem)
        }
        
        mainMenu.itemWithTitle(name)!.state = (strimsController.strimsList[name]! ? NSOnState : NSOffState)
    }
    
    func nameDeleteClicked(sender: NSMenuItem) {
        mainMenu.removeItem(sender.parentItem!)
        strimsController.removeStrim(sender.menu!.title)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            self.refresh()
        })
    }
    
    func nameClicked(sender: NSMenuItem) {
        dispatch_async(backgroundQueue, {
            self.strimsController.initStrim(sender.title)
        })
    }
    
    func refresh() {
        //only dispatch refreshmenuitem, refresh itself must be dispatched by the caller
        self.strimsController.paraScan(self.strimsController.strimsList)
        let group: dispatch_group_t = dispatch_group_create()
        for (name, _) in self.strimsController.strimsList {
            dispatch_group_async(group, backgroundQueue, {
                self.refreshMenuItem(name)
            })
        }
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        self.mainMenu.update()
    }
    
    func timerEvents(sender: NSTimer) {
        //did streams change?
        dispatch_async(backgroundQueue, {
            let temp: Dictionary = self.strimsController.strimsList
            self.refresh()
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
        if(notificationsAreOn == true) {center.scheduleNotification(notify);}
    }
    
    func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }
    
    /*****************************************************/
     /*													 */
     /*					IBActions						 */
     /*													 */
     /*****************************************************/
    @IBAction func addButtonClicked(sender: NSMenuItem) {
        textFieldWindow.makeKeyAndOrderFront(sender)
        NSApp.activateIgnoringOtherApps(true)
    }
    
    @IBAction func refreshButtonClicked(sender: NSMenuItem) {
        dispatch_async(backgroundQueue, {
            self.refresh()
        })
    }
    
    @IBAction func addTextFieldReturn(sender: NSTextField) {
        strimsController.addStrim(sender.stringValue)
        dispatch_async(backgroundQueue, {
            self.refresh()
        })
        textFieldWindow.orderOut(sender)
    }
    @IBAction func notificationButtonClicked(sender: NSMenuItem) {
        if notificationButton.state == NSOnState && notificationsAreOn == true {
            notificationsAreOn = false
            notificationButton.state = NSOffState
        }
            
        else if notificationButton.state == NSOffState && notificationsAreOn == false {
            notificationsAreOn = true
            notificationButton.state = NSOnState
        }
            
        else {
            print("discrepency in notifications enabled and state");
        }
    }
    /*****************************************************/
    /*													 */
    /*					End IBActions					 */
    /*													 */
    /*****************************************************/
}

class SubWindow: NSWindow {
    override var canBecomeKeyWindow: Bool {
        get {
            return true
        }
    }
}

/*****************************************************/
 /*													 */
 /*					MenuItem Struct					 */
 /*													 */
 /*****************************************************/

struct nameMenuItem {
    private let deleteMenu: NSMenu
    private var deleteItem: NSMenuItem
    private let item: NSMenuItem
    
    init(name: String, online: Bool) {
        
        item = NSMenuItem(title: name, action: "nameClicked:", keyEquivalent: "")
        deleteItem = NSMenuItem(title: "Delete", action: "nameDeleteClicked:", keyEquivalent: "")
        deleteMenu = NSMenu()
        deleteMenu.title = name
        deleteMenu.autoenablesItems = false
        
        item.enabled = true
        item.onStateImage = NSImage(named: "stateImage")
        deleteItem.enabled = true
        deleteMenu.addItem(deleteItem)
        
        if online {item.state = NSOnState}
    }
    
    subscript() -> (NSMenuItem, NSMenu) {
        get {
            return (item, deleteMenu)
        }
    }
}