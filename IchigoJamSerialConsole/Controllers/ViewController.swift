//
//  ViewController.swift
//  IchigoJamConsle
//
//  Created by titoi2 on 2015/03/30.
//  Copyright (c) 2015年 titoi2. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, IJCSerialManagerDelegate, KeyInputDelegate, IJCTextViewDelegate {

    
    let SERIAL_NOT_USE = "Serial not use"
    let SEGUE_LOAD = "load"
    
    @IBOutlet weak var serialPopUpButton: NSPopUpButton!
    @IBOutlet weak var openCloseButton: NSButton!

    @IBOutlet var mainView: MainView!
    
    @IBOutlet var logView: IJCTextView!
    
    @IBOutlet weak var connectImageView: NSImageView!
    
    @IBOutlet weak var logDispView: NSTextField!

    
    let serialManager = IJCSerialManager.sharedInstance
    
    let connectOnImage = NSImage(named: "connect_on")
    let connectOffImage = NSImage(named: "connect_off")
    
    
    var keyLog:String = ""
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainView.delegate = self

        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "serialPortsWereConnected:", name: ORSSerialPortsWereConnectedNotification, object: nil)
        nc.addObserver(self, selector: "serialPortsWereDisconnected:", name: ORSSerialPortsWereDisconnectedNotification, object: nil)
        
        logView.keyDownDelegate = self
        serialManager.delegate = self
        
        refreshPortsPopup()
    }

    
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        serialManager.close()
    }
    
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    
    
    func refreshPortsPopup() {
        serialPopUpButton.removeAllItems()
        serialPopUpButton.addItemWithTitle(SERIAL_NOT_USE)
        let ports = serialManager.ports()
        for p in ports {
            let s:ORSSerialPort = p as! ORSSerialPort
            NSLog("path:\(s.path)")
            serialPopUpButton.addItemWithTitle(s.path)
        }
    }
    
    
    @IBAction func pushSerialOpenCloseButton(sender: NSButton) {
        let path:NSString = serialPopUpButton.titleOfSelectedItem!
        
        serialManager.open(path as String)
    }
    

    

    
    
    
    
    

    func onKeyDown(theEvent: NSEvent) {
        NSLog("VC onKeyDown keycode:%x", theEvent.keyCode);
        keyDownProc(theEvent)
    }
    
    func onKeyUp(theEvent: NSEvent) {
    }
    
    func onTextViewKeyDown(theEvent: NSEvent) {
        keyDownProc(theEvent)        
    }
    
    

    func keyDownProc(theEvent: NSEvent) {
        if let str = theEvent.characters {
            let fs = first(str.unicodeScalars)
            if fs == nil {
                return
            }
            let c:Int = Int(fs!.value)
            NSLog("VC onKeyDown char:%x", c);
            var code:Int = -1
            var keyInLog:String = ""
            if c < 0x100 {
                code = c
                switch c {
                case 0x7F:
                    code = 8    // DELETEキーをバックスペースに変換
                case 0x0D:
                    let keycode = theEvent.keyCode
                    if keycode == 36 {
                        code = 10   // ENTERキーを0x0Aに変換
                    }
                default:
                    code = c
                }
            } else {
                switch c {
                case NSUpArrowFunctionKey:
                    code = Int(ICHIGOJAM_KEY_UP)
                    keyInLog = "↑"

                case NSDownArrowFunctionKey:
                    code = Int(ICHIGOJAM_KEY_DOWN)
                    keyInLog = "↓"

                case NSLeftArrowFunctionKey:
                    code = Int(ICHIGOJAM_KEY_LEFT)
                    keyInLog = "←"

                case NSRightArrowFunctionKey:
                    code = Int(ICHIGOJAM_KEY_RIGHT)
                    keyInLog = "→"
                    
                case NSDeleteFunctionKey:
                    code = 0x7F
                    keyInLog = "DEL"
                    
                case NSF1FunctionKey:
                    serialManager.sendString(FUNCTION_KEY_STR_01)
                    keyInLog = "F1"

                case NSF2FunctionKey:
                    serialManager.sendString(FUNCTION_KEY_STR_02)
                    keyInLog = "F2"

                case NSF3FunctionKey:
                    serialManager.sendString(FUNCTION_KEY_STR_03)
                    keyInLog = "F3"

                case NSF4FunctionKey:
                    serialManager.sendString(FUNCTION_KEY_STR_04)
                    keyInLog = "F4"

                case NSF5FunctionKey:
                    serialManager.sendString(FUNCTION_KEY_STR_05)
                    keyInLog = "F5"

                case NSF6FunctionKey:
                    serialManager.sendString(FUNCTION_KEY_STR_06)
                    keyInLog = "F6"

                case NSF7FunctionKey:
                    serialManager.sendString(FUNCTION_KEY_STR_07)
                    keyInLog = "F7"

                case NSF8FunctionKey:
                    serialManager.sendString(FUNCTION_KEY_STR_08)
                    keyInLog = "F8"
                    
                default:
                    code = 0
                }
            }
            if code != -1 {
                let c8 = UInt8(code)
                keyInLog = codeToEchobackString(code)
                serialManager.sendByte(c8)
            }
            appendEchoString( keyInLog)
        }
    
    }

    let MAX_LOG_LENGTH = 200;
    func appendEchoString(log:String) {
        keyLog += " " + log
        let len = count(keyLog)
        if (len > MAX_LOG_LENGTH ) {
            let start = len - MAX_LOG_LENGTH
            keyLog = keyLog.substringFromIndex(advance(keyLog.startIndex, start))
        }
        logDispView.stringValue = keyLog
    }
    
    
    // 8bitコードをエコーバック用文字列に変換
    func codeToEchobackString(code:Int) -> String {
        var res = ""
        switch code {
        case 0x08: res = "BS"
//        case 0x0A: res = "LF"
//        case 0x0D: res = "CR"
        case 0x1B: res = "ESC"

        case 0x1C: res = "←"
        case 0x1D: res = "→"
        case 0x1E: res = "↑"
        case 0x1F: res = "↓"

        case 0x20: res = "SP"
        case 0x00 ... 0x1A: res = String(bytes: [0x5E,UInt8( code+0x40), 0], encoding: NSShiftJISStringEncoding)!
        case 0x7F: res = "DEL"
        case 0x80 ... 0xA1, 0xE0 ... 0xFF:
            res = String(format: "%02X", code)
        default:
            res = String(bytes: [UInt8(code),0], encoding: NSShiftJISStringEncoding)!
        }
        return res
    }
    
    @IBAction func pushKanaButton(sender: NSButton) {
//        sendByte(15)
        stringInput()
    }
    
    
    @IBAction func pushInsButton(sender: NSButton) {
        serialManager.sendByte(17)
    }
    
    @IBAction func pushLoadButton(sender: NSButton) {
        self.performSegueWithIdentifier(self.SEGUE_LOAD, sender: self)
    }

    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SEGUE_LOAD {
//            let nextViewController = segue.destinationController as! FileLoadViewController
//            nextViewController.fileUrl = selectedFileUrl
        }
    }
    
    func stringInput() {
        let alert = NSAlert()
        alert.addButtonWithTitle("OK")
        alert.addButtonWithTitle("Cancel")
        alert.messageText = "半角カナ文字を入力して下さい"
        alert.alertStyle = NSAlertStyle.InformationalAlertStyle
        
        
        let rect = CGRectMake(0, 0, 200, 20)
        var nameBox =  NSTextField(frame: rect)
        alert.accessoryView = nameBox
        if  alert.runModal() == NSAlertFirstButtonReturn {
            if !nameBox.stringValue.isEmpty {
                serialManager.sendString(nameBox.stringValue)
            }
        }

    }

    
    func serialPortRemoved() {
        serialManager.close()
    }

    func serialPortOpene() {
        connectImageView.image = connectOnImage
    }
    
    func serialPortClosed() {
        connectImageView.image = connectOffImage
    }
    
    func serialPortReceived(data: NSData!) {
        if let string = NSString(data: data, encoding: NSShiftJISStringEncoding) {
            NSLog("received:\(string)")
            
            logView.selectAll(nil)
            var wholeRange:NSRange = logView.selectedRange()
            var endRange:NSRange  = NSMakeRange(wholeRange.length, 0)
            logView.setSelectedRange(endRange)
            logView.insertText(string)
            
            //描画を一時的に止める
            logView.textStorage?.beginEditing()
            
            //テキストを追加
            let atrstr = NSAttributedString(string: string as String)
            logView.textStorage?.appendAttributedString(atrstr)
            
            //描画再開
            logView.textStorage?.endEditing()
            
            //最終行へスクロール
            let theEvent: NSEvent = NSEvent()
            logView.autoscroll(theEvent)
            
        } else {
            //描画を一時的に止める
            logView.textStorage?.beginEditing()
            
            //テキストを追加
            let atrstr = NSAttributedString(string: "デコードエラー")
            logView.textStorage?.appendAttributedString(atrstr)
            
            //描画再開
            logView.textStorage?.endEditing()
            
            //最終行へスクロール
            let theEvent: NSEvent = NSEvent()
            logView.autoscroll(theEvent)
            
        }
    }
    
    func serialPortsWereConnected() {
        refreshPortsPopup()
    }
    func serialPortsWereDisconnected() {
        refreshPortsPopup()
    }

}


