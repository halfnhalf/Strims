//
//  InstallController.swift
//  Strims
//
//  Created by Zachary Clute on 12/29/15.
//  Copyright © 2015 Zachary Clute. All rights reserved.
//
import Cocoa

class InstallController: NSObject {
    let installCommand: String = "/usr/bin/sudo"
    var isInstalled: Bool = false
    
    @IBOutlet weak var installWindow: NSWindow!
    
    enum InstallError: ErrorType {
        case NotInstalled
    }
    
    override init() {
        super.init()
    }
    
    func checkForLivestreamer() throws {
        let fileManager = NSFileManager.defaultManager()
        
        guard fileManager.fileExistsAtPath(COMMAND) else {
            throw InstallError.NotInstalled
        }
        
        isInstalled = true
    }
    
    func askToInstallLivestreamer() {
        installWindow.makeKeyAndOrderFront(nil)
        NSApp.activateIgnoringOtherApps(true)
    }
    
    @IBAction func yesButtonClicked(sender: AnyObject) {
        //user wants to install livestreamer
        NSAppleScript(source: "do shell script \"sudo easy_install livestreamer\" with administrator privileges")!.executeAndReturnError(nil)
        do {
            try checkForLivestreamer()
        } catch {}
        
        if !isInstalled {
            NSApplication.sharedApplication().terminate(self)
        }
    }
    @IBAction func noButtonClicked(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(self)
    }
    
}
