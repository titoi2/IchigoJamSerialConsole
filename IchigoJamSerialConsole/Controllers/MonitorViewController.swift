//
//  MonitorViewController.swift
//  IchigoJamSerialConsole
//
//  Created by titoi2 on 2015/08/19.
//  Copyright (c) 2015年 titoi2. All rights reserved.
//

import Cocoa

class MonitorViewController: NSViewController, MonitorManagerDelegate {

    @IBOutlet weak var imageView: NSImageView!

    
    let monitorManager = MonitorManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
 
    override func viewDidAppear() {
        super.viewDidDisappear()
        monitorManager.delegate = self
        monitorManager.takeImage()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        monitorManager.delegate = nil
    }

    func onDispChange(img:NSImage) {
        
          dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.imageView.image = img
          })
    }


}
