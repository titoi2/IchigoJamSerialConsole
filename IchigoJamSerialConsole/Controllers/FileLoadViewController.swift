//
//  FileLoadViewController.swift
//  IchigoJamSerialConsole
//
//  Created by titoi2 on 2015/04/11.
//  Copyright (c) 2015年 titoi2. All rights reserved.
//

import Cocoa

class FileLoadViewController: NSViewController {

    @IBOutlet weak var infoLabel: NSTextField!
    @IBOutlet weak var progressIndicator:NSProgressIndicator!
    
    let serialPortManager = ORSSerialPortManager.sharedSerialPortManager()
    var serialPort: ORSSerialPort?
    
    var fileUrl:NSURL? = nil
    let serialManager = IJCSerialManager.sharedInstance
    var loadStop:Bool = false


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        
    }
    
    override func viewDidAppear() {
        progressIndicator.startAnimation(self)
        
        
        let panel:NSOpenPanel = NSOpenPanel()
        panel.beginWithCompletionHandler {  [unowned self] (result:Int) -> Void  in
            if result == NSFileHandlingPanelOKButton {
                self.fileUrl = panel.URLs[0] as? NSURL
                
                let queue = dispatch_queue_create("queueFileLoad", DISPATCH_QUEUE_SERIAL)
                dispatch_async(queue, {
                    self.load()
                    
                    dispatch_sync(dispatch_get_main_queue(), {
                        
                        
                        }
                    )
                })
            } else {
                self.dismissViewController(self)
            }
        }
    }
    
    override func viewDidDisappear() {
    }
    
    func load() {
        if fileUrl == nil {
            return
        }
        let theDoc = fileUrl!
        var err: NSError?;
        let data = NSData(contentsOfURL: theDoc,
            options: NSDataReadingOptions.DataReadingMappedIfSafe, error: &err)
        if let nerr = err {
            NSLog("FILE READ ERROR:\(nerr.localizedDescription)")
            return
        }
        if let ndata = data {
            self.loadData2Ichigojam(ndata)
        }

    }
    
    // IchigoJamにファイルデータをプログラムとして転送する
    func loadData2Ichigojam(data:NSData) {
        let count:Int! = data.length
        var buf = [UInt8](count: count, repeatedValue: 0)
        data.getBytes(&buf, length: count)
        
        // プログラム停止、ESC送信
        serialManager.sendByte(ICHIGOJAM_KEY_ESC)
        NSThread.sleepForTimeInterval(0.05)
        serialManager.sendString("CLS \u{0000A}")
        NSThread.sleepForTimeInterval(0.05)
        // NEWで既存プログラム消去
        serialManager.sendString("NEW \u{0000A}")
        NSThread.sleepForTimeInterval(0.05)
        progressIndicator.maxValue = Double(buf.count)
        loadStop = false
        for var i=0; i < buf.count; i++ {
            if loadStop {
                break
            }
            progressIndicator.incrementBy(1.0)
            let d = buf[i]
            if d == 13 {
                // CRを除去
                continue
            }
            serialManager.sendByte(d)
            NSThread.sleepForTimeInterval(0.02)
        }
        // 一応、最後に改行
        if !loadStop {
            serialManager.sendString("\u{0000A}")
        }
        dismissViewController(self)
    }
    
    @IBAction func pushCancelButton(sender: NSButton) {
        loadStop = true

        dismissViewController(self)
    }
}
