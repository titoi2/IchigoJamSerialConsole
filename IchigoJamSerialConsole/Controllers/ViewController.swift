//
//  ViewController.swift
//  IchigoJamConsle
//
//  Created by titoi2 on 2015/03/30.
//  Copyright (c) 2015年 titoi2. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, ORSSerialPortDelegate, KeyInputDelegate, IJCTextViewDelegate {

    
    let SERIAL_NOT_USE = "Serial not use"
    
    @IBOutlet weak var serialPopUpButton: NSPopUpButton!
    @IBOutlet weak var openCloseButton: NSButton!

    @IBOutlet var mainView: MainView!
    
    @IBOutlet var logView: IJCTextView!
    
    @IBOutlet weak var connectImageView: NSImageView!
    
    let serialPortManager = ORSSerialPortManager.sharedSerialPortManager()
    var serialPort: ORSSerialPort?

    let connectOnImage = NSImage(named: "connect_on")
    let connectOffImage = NSImage(named: "connect_off")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainView.delegate = self

        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "serialPortsWereConnected:", name: ORSSerialPortsWereConnectedNotification, object: nil)
        nc.addObserver(self, selector: "serialPortsWereDisconnected:", name: ORSSerialPortsWereDisconnectedNotification, object: nil)
        
        logView.keyDownDelegate = self

        refreshPortsPopup()
    }

    
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        if  self.serialPort != nil {
            self.serialPort?.close()
            self.serialPort?.delegate = nil
            self.serialPort = nil
        }
    }
    
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    
    
    func refreshPortsPopup() {
        serialPopUpButton.removeAllItems()
        serialPopUpButton.addItemWithTitle(SERIAL_NOT_USE)
        let ports = serialPortManager.availablePorts
        for p in ports {
            let s:ORSSerialPort = p as ORSSerialPort
            NSLog("path:\(s.path)")
            serialPopUpButton.addItemWithTitle(s.path)
        }
    }
    
    
    @IBAction func pushSerialOpenCloseButton(sender: NSButton) {
        let path:NSString = serialPopUpButton.titleOfSelectedItem!
        
        
        if  self.serialPort != nil {
            self.serialPort?.close()
            self.serialPort?.delegate = nil
            self.serialPort = nil
        }
        self.serialPort = ORSSerialPort(path: path)
        self.serialPort?.baudRate = NSNumber(int: 115200)
        self.serialPort?.delegate = self

        if let port = self.serialPort {
            if (port.open) {
                port.close()
            } else {
                port.open()
            }
        }
    }
    

    
    // MARK: - ORSSerialPortDelegate
    
    func serialPortWasOpened(serialPort: ORSSerialPort!) {
        connectImageView.image = connectOnImage
    }
    
    func serialPortWasClosed(serialPort: ORSSerialPort!) {
        connectImageView.image = connectOffImage
    }
    
    func serialPort(serialPort: ORSSerialPort!, didReceiveData data: NSData!) {
        NSLog("Receive Length:\(data.length)")
        /*
        let bytes = UnsafePointer<UInt8>(data.bytes)
        for i in 0..<data.length {
            NSLog("buf DATA:%02X",bytes[i])
        }
        */
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
            let atrstr = NSAttributedString(string: string)
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

    
    
    
    func serialPortWasRemovedFromSystem(serialPort: ORSSerialPort!) {
        self.serialPort = nil
        self.openCloseButton.title = "Open"
    }
    
    func serialPort(serialPort: ORSSerialPort!, didEncounterError error: NSError!) {
        println("SerialPort \(serialPort) encountered an error: \(error)")
    }
    
    
    
    // MARK: - Notifications
    
    func serialPortsWereConnected(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let connectedPorts = userInfo[ORSConnectedSerialPortsKey] as [ORSSerialPort]
            println("Ports were connected: \(connectedPorts)")
            self.postUserNotificationForConnectedPorts(connectedPorts)
            refreshPortsPopup()
        }
    }
    
    func serialPortsWereDisconnected(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let disconnectedPorts: [ORSSerialPort] = userInfo[ORSDisconnectedSerialPortsKey] as [ORSSerialPort]
            println("Ports were disconnected: \(disconnectedPorts)")
            self.postUserNotificationForDisconnectedPorts(disconnectedPorts)
            refreshPortsPopup()
        }
    }
    
    func postUserNotificationForConnectedPorts(connectedPorts: [ORSSerialPort]) {
        let unc = NSUserNotificationCenter.defaultUserNotificationCenter()
        for port in connectedPorts {
            let userNote = NSUserNotification()
            userNote.title = NSLocalizedString("Serial Port Connected", comment: "Serial Port Connected")
            userNote.informativeText = "Serial Port \(port.name) was connected to your Mac."
            userNote.soundName = nil;
            unc.deliverNotification(userNote)
        }
    }
    
    func postUserNotificationForDisconnectedPorts(disconnectedPorts: [ORSSerialPort]) {
        let unc = NSUserNotificationCenter.defaultUserNotificationCenter()
        for port in disconnectedPorts {
            let userNote = NSUserNotification()
            userNote.title = NSLocalizedString("Serial Port Disconnected", comment: "Serial Port Disconnected")
            userNote.informativeText = "Serial Port \(port.name) was disconnected from your Mac."
            userNote.soundName = nil;
            unc.deliverNotification(userNote)
        }
    }
    
    let lock = NSLock()

    func sendByte(param:UInt8) {
        var code:UInt8 = param
        let data = NSData(bytes: &code, length:sizeof(UInt8))
        lock.lock()
        serialPort?.sendData(data)
        lock.unlock()
    }
    
    func sendBytes(s:[UInt8]) {
        for c in s {
            sendByte(c)
        }
    }

    func sendString(str:String) {
        if let buf = str2UInt8Array(str) {
            sendBytes(buf)
        }
    }

    func onKeyDown(theEvent: NSEvent) {
        NSLog("VC onKeyDown keycode:%x", theEvent.keyCode);
        keyDownProc(theEvent)
    }
    
    func onTextViewKeyDown(theEvent: NSEvent) {
        keyDownProc(theEvent)        
    }
    

    func keyDownProc(theEvent: NSEvent) {
        if let str = theEvent.characters {
            let c:Int = Int(first(str.unicodeScalars)!.value)
            NSLog("VC onKeyDown char:%x", c);
            var code:UInt8
            if c < 0x100 {
                switch (c) {
                case 0x7F:
                    code = 8    // DELETEキーをバックスペースに変換
                case 0x0D:
                    code = 10   // ENTERキーをENTERに変換
                default:
                    code = UInt8(c)
                    
                }
            } else {
                switch c {
                case NSUpArrowFunctionKey:
                    code = 30
                case NSDownArrowFunctionKey:
                    code = 31
                case NSLeftArrowFunctionKey:
                    code = 28
                case NSRightArrowFunctionKey:
                    code = 29
                    
                case NSDeleteFunctionKey:
                    code = 0x7F
                    
                case NSF1FunctionKey:
                    sendString(FUNCTION_KEY_STR_01)
                    return
                case NSF2FunctionKey:
                    sendString(FUNCTION_KEY_STR_02)
                    return
                case NSF3FunctionKey:
                    sendString(FUNCTION_KEY_STR_03)
                    return
                case NSF4FunctionKey:
                    sendString(FUNCTION_KEY_STR_04)
                    return
                case NSF5FunctionKey:
                    sendString(FUNCTION_KEY_STR_05)
                    return
                case NSF6FunctionKey:
                    sendString(FUNCTION_KEY_STR_06)
                    return
                case NSF7FunctionKey:
                    sendString(FUNCTION_KEY_STR_07)
                    return
                case NSF8FunctionKey:
                    sendString(FUNCTION_KEY_STR_08)
                    return
                    
                default:
                    code = 0
                }
            }
            sendByte(code)
        }
    
    }

    
    @IBAction func pushKanaButton(sender: NSButton) {
//        sendByte(15)
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
                sendString(nameBox.stringValue)
            }
        }
    }
    
    
    @IBAction func pushInsButton(sender: NSButton) {
        sendByte(17)
    }
    
    
}

