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
    
    @IBOutlet weak var echoDispView: NSTextField!

    let serialPortManager = ORSSerialPortManager.sharedSerialPortManager()
    var serialPort: ORSSerialPort?

    let connectOnImage = NSImage(named: "connect_on")
    let connectOffImage = NSImage(named: "connect_off")
    
    
    var echoString:String = ""
    
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
        if let sp = serialPort {
            lock.lock()
            if sp.sendData(data) {
//                NSLog("SEND SUCCESS data:%02X", code)
            } else {
//                NSLog("SEND ERROR")
            }
            lock.unlock()
        }
    }
    
    func sendBytes(s:[UInt8]) {
        for c in s {
            sendByte(c)
            NSThread.sleepForTimeInterval(0.02)
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
            var echoback:String = ""
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
                    echoback = "↑"

                case NSDownArrowFunctionKey:
                    code = Int(ICHIGOJAM_KEY_DOWN)
                    echoback = "↓"

                case NSLeftArrowFunctionKey:
                    code = Int(ICHIGOJAM_KEY_LEFT)
                    echoback = "←"

                case NSRightArrowFunctionKey:
                    code = Int(ICHIGOJAM_KEY_RIGHT)
                    echoback = "→"
                    
                case NSDeleteFunctionKey:
                    code = 0x7F
                    echoback = "DEL"
                    
                case NSF1FunctionKey:
                    sendString(FUNCTION_KEY_STR_01)
                    echoback = "F1"

                case NSF2FunctionKey:
                    sendString(FUNCTION_KEY_STR_02)
                    echoback = "F2"

                case NSF3FunctionKey:
                    sendString(FUNCTION_KEY_STR_03)
                    echoback = "F3"

                case NSF4FunctionKey:
                    sendString(FUNCTION_KEY_STR_04)
                    echoback = "F4"

                case NSF5FunctionKey:
                    sendString(FUNCTION_KEY_STR_05)
                    echoback = "F5"

                case NSF6FunctionKey:
                    sendString(FUNCTION_KEY_STR_06)
                    echoback = "F6"

                case NSF7FunctionKey:
                    sendString(FUNCTION_KEY_STR_07)
                    echoback = "F7"

                case NSF8FunctionKey:
                    sendString(FUNCTION_KEY_STR_08)
                    echoback = "F8"
                    
                default:
                    code = 0
                }
            }
            if code != -1 {
                let c8 = UInt8(code)
                echoback = codeToEchobackString(c8)
                sendByte(c8)
            }
            appendEchoString( echoback)
        }
    
    }

    let MAX_ECHO_LENGTH = 200;
    func appendEchoString(echo:String) {
        echoString += " " + echo
        let len = countElements(echoString)
        NSLog("echoString:\(echoString)")
        if (len > MAX_ECHO_LENGTH ) {
            let start = len - MAX_ECHO_LENGTH
            echoString = echoString.substringFromIndex(advance(echoString.startIndex, start))
            NSLog("AFTER echoString:\(echoString)")
        }
        echoDispView.stringValue = echoString
    }
    
    
    // 8bitコードをエコーバック用文字列に変換
    func codeToEchobackString(code:UInt8) -> String {
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
        case 0x00 ... 0x1A: res = String(bytes: [0x5E, code+0x40, 0], encoding: NSShiftJISStringEncoding)!
        case 0x7F: res = "DEL"
        case 0x80 ... 0xA1, 0xE0 ... 0xFF:
            res = String(format: "%02X", code)
        default:
            res = String(bytes: [code,0], encoding: NSShiftJISStringEncoding)!
        }
        return res
    }
    
    @IBAction func pushKanaButton(sender: NSButton) {
//        sendByte(15)
        stringInput()
    }
    
    
    @IBAction func pushInsButton(sender: NSButton) {
        sendByte(17)
    }
    
    @IBAction func pushLoadButton(sender: NSButton) {
        let panel:NSOpenPanel = NSOpenPanel()
        
        panel.beginWithCompletionHandler {  [unowned self] (result:Int) -> Void  in
            if result == NSFileHandlingPanelOKButton {
                let theDoc: NSURL = panel.URLs[0] as NSURL
                let path = theDoc.absoluteString
                  var err: NSError?;
                let data = NSData(contentsOfURL: theDoc,
                    options: NSDataReadingOptions.DataReadingMappedIfSafe,
                    error: &err)
                if let nerr = err {
                    NSLog("FILE READ ERROR:\(nerr.localizedDescription)")
                    return
                }
                if let ndata = data {
                    self.loadData2Ichigojam(ndata)
                }
            }
        }
    }

    
    // IchigoJamにファイルデータをプログラムとして転送する
    func loadData2Ichigojam(data:NSData) {
        let count:Int! = data.length
        var buf = [UInt8](count: count, repeatedValue: 0)
        data.getBytes(&buf, length: count)
        
        // プログラム停止、ESC送信
        sendByte(ICHIGOJAM_KEY_ESC)
        NSThread.sleepForTimeInterval(0.05)
        sendString("CLS \u{0000A}")
        NSThread.sleepForTimeInterval(0.05)
        // NEWで既存プログラム消去
        sendString("NEW \u{0000A}")
        NSThread.sleepForTimeInterval(0.05)
        for d in buf {
            if d == 13 {
                // CRを除去
                continue
            }
            sendByte(d)
            NSThread.sleepForTimeInterval(0.02)
        }
        // 一応、最後に改行
        sendString("\u{0000A}")

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
                sendString(nameBox.stringValue)
            }
        }

    }
    
}

