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
    
    var url:NSURL? = nil
    let serialManager = IJCSerialManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        
        progressIndicator.startAnimation(self)
    }
    
    
    
    func load() {
        if url == nil {
            return
        }
        let theDoc = url!
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
        for d in buf {
            if d == 13 {
                // CRを除去
                continue
            }
            serialManager.sendByte(d)
            NSThread.sleepForTimeInterval(0.02)
        }
        // 一応、最後に改行
        serialManager.sendString("\u{0000A}")
        
    }
    @IBAction func pushCancelButton(sender: NSButton) {
        dismissViewController(self)
    }
}
