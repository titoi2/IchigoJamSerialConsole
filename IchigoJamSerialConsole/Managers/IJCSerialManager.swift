//
//  SerialManager.swift
//  IchigoJamSerialConsole
//
//  Created by titoi2 on 2015/04/12.
//  Copyright (c) 2015年 titoi2. All rights reserved.
//

import Foundation


protocol IJCSerialManagerDelegate {
    func serialPortRemoved()
    func serialPortOpened()
    func serialPortClosed()
    func serialPortReceived(data: NSData!)
    func serialPortsWereConnected()
    func serialPortsWereDisconnected()

}

class IJCSerialManager:NSObject, ORSSerialPortDelegate {
    
    let LOCAL_DEBUG = false

    static let sharedInstance = IJCSerialManager()
    
    
    let serialPortManager = ORSSerialPortManager.sharedSerialPortManager()
    var serialPort: ORSSerialPort?

    let lock = NSLock()
    
    var delegate:IJCSerialManagerDelegate?
    
    
    private override init() {
    }

    func ports() -> NSArray {
        let ports = serialPortManager.availablePorts
        return ports
    }
    
    
    func open(path:String) {
        self.serialPort = ORSSerialPort(path: path as String)
        self.serialPort?.baudRate = NSNumber(int: 115200)
        self.serialPort?.delegate = self
        
        if let port = self.serialPort {
            port.open()
        }
   
    }

    func close() {
        if  self.serialPort != nil {
            self.serialPort?.close()
            self.serialPort?.delegate = nil
            self.serialPort = nil
        }
    }
    
    
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

    
    
    // MARK: - ORSSerialPortDelegate
    
    func serialPortWasOpened(serialPort: ORSSerialPort!) {
        if let d = delegate {
            d.serialPortOpened()
        }
    }
    
    func serialPortWasClosed(serialPort: ORSSerialPort!) {
        if let d = delegate {
            d.serialPortClosed()
        }
    }
    
    func serialPort(serialPort: ORSSerialPort!, didReceiveData data: NSData!) {
        if LOCAL_DEBUG {
            NSLog("Receive Length:\(data.length)")
        }
        if let d = delegate {
            d.serialPortReceived(data)
        }
        /*
        let bytes = UnsafePointer<UInt8>(data.bytes)
        for i in 0..<data.length {
        NSLog("buf DATA:%02X",bytes[i])
        }
        */
    }
    

    func serialPortWasRemovedFromSystem(serialPort: ORSSerialPort!) {
        self.serialPort = nil
        if let d = delegate {
            d.serialPortRemoved()
        }
    }
    
    func serialPort(serialPort: ORSSerialPort!, didEncounterError error: NSError!) {
        println("SerialPort \(serialPort) encountered an error: \(error)")
    }
    
    
    
    // MARK: - Notifications
    
    func serialPortsWereConnected(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let connectedPorts = userInfo[ORSConnectedSerialPortsKey] as! [ORSSerialPort]
            println("Ports were connected: \(connectedPorts)")
            self.postUserNotificationForConnectedPorts(connectedPorts)
            if let d = delegate {
                d.serialPortsWereConnected()
            }
        }
    }

    func serialPortsWereDisconnected(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let disconnectedPorts: [ORSSerialPort] = userInfo[ORSDisconnectedSerialPortsKey] as! [ORSSerialPort]
            println("Ports were disconnected: \(disconnectedPorts)")
            self.postUserNotificationForDisconnectedPorts(disconnectedPorts)
            if let d = delegate {
                d.serialPortsWereDisconnected()
            }
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

    func serialIsOpen() -> Bool {
        if let sp = self.serialPort {
            return sp.open
        }
        return false
    }
}

