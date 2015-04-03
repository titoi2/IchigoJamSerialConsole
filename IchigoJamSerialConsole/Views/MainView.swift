//
//  MainView.swift
//  IchigoJamConsle
//
//  Created by titoi2 on 2015/03/30.
//  Copyright (c) 2015年 titoi2. All rights reserved.
//

import Cocoa

protocol KeyInputDelegate {
    func onKeyDown(theEvent: NSEvent);
}

class MainView: NSView {

    var delegate:KeyInputDelegate?
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    func acceptsFirstResponder() -> Bool {
        return true
    }
    
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    
    override func keyDown(theEvent: NSEvent) {
        NSLog("Key Down");
        if  let delegate = self.delegate {
            delegate.onKeyDown(theEvent)
        }
    }

}
