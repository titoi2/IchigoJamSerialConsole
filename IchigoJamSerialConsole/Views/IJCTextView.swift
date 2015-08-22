//
//  IJCTextView.swift
//  IchigoJamSerialConsole
//
//  Created by titoi2 on 2015/04/01.
//  Copyright (c) 2015年 titoi2. All rights reserved.
//

import Cocoa

protocol IJCTextViewDelegate {
    func onTextViewKeyDown(theEvent: NSEvent)
}

class IJCTextView: NSTextView {
    
    var keyDownDelegate : IJCTextViewDelegate?

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
 
    override func keyDown(theEvent: NSEvent) {
//        NSLog("override keyDown")
        keyDownDelegate?.onTextViewKeyDown(theEvent)
    }

}
