//
//  InstallController.swift
//  Strims
//
//  Created by Zachary Clute on 12/29/15.
//  Copyright © 2015 Zachary Clute. All rights reserved.
//
import Cocoa

class InstallController: NSObject {
    @IBOutlet weak var installWindow: NSWindow!
    
    override init() {
        super.init()
    }
    
    func checkForLivestreamer() throws {
        let fileManager = NSFileManager.defaultManager()
        
        guard fileManager.fileExistsAtPath(COMMAND) else {
            throw InstallError.NotInstalled
        }
    }
    
    func askToInstallLivestreamer() {
        installWindow.makeKeyAndOrderFront(nil)
        NSApp.activateIgnoringOtherApps(true)
    }
    
    enum InstallError: ErrorType {
        case NotInstalled
    }
}
