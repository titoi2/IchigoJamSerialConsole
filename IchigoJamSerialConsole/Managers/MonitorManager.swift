//
//  MonitorManager.swift
//  IchigoJamSerialConsole
//
//  Created by titoi2 on 2015/08/18.
//  Copyright (c) 2015年 titoi2. All rights reserved.
//

import Foundation
import Cocoa


protocol MonitorManagerDelegate {
    func onDispChange(img:NSImage)
}

class MonitorManager:NSObject {
    
    static let sharedInstance = MonitorManager()
    
    let SCREEN_CHARA_WIDTH = 32
    let SCREEN_CHARA_HEIGTH = 24
    
    var width:Int = 0
    var height:Int = 0
    var cursorX:Int = 0
    var cursorY:Int = 0
    
    var vram:[[UInt8]]
//    var screenImage: NSImage
    
    enum InterpreterState {
        case Idle
        case TakeX
        case TakeY
    }
    
    var interpreterState:InterpreterState = InterpreterState.Idle
    var fontImage:NSImage = NSImage(named: "charas")!
    
    var delegate:MonitorManagerDelegate? = nil
    
    private  override init() {
        width = SCREEN_CHARA_WIDTH
        height = SCREEN_CHARA_HEIGTH
        vram = [[UInt8]](count: height, repeatedValue: [UInt8](count: width, repeatedValue: 0x20))
        
        super.init()
        
        for y in 0 ..< height {
            for x in 0 ..< width {
                putChar( x, y: y, c: 0x20)
            }
        }

    }
    
    
    func interpret(str:[UInt8]) {
        for c in str {
            switch interpreterState {
            case .TakeX:
                cursorX = Int(c) - 32 - 1
                interpreterState = .TakeY
                break
                
            case .TakeY:
                cursorY = Int(c) - 32 - 1
                interpreterState = .Idle
                break
                

                
            default:
                switch c {
                case 0x0A:
                    cursorX = 0
                    cursorY++
                    if cursorY >= height {
                        cursorY = height - 1
                    }
                    break
                    
                case 0x0C:
                    for y in cursorY ..< height {
                        for x in cursorX ..< width {
                            putChar( x, y: y, c: 0x20)
                        }
                    }
                    vram2ImageCG()
                    break
                    
                case 0x13:
                    cursorX = 0
                    cursorY = 0
                    break
                    
                case 0x15:
                    interpreterState = .TakeX
                    break
                    
                default:
                    putChar( cursorX, y: cursorY, c: c)
                    
                    cursorX++
                    if cursorX >= width {
                        cursorX = 0
                    }
                    
                    vram2ImageCG()
                    break
                }
                
            }
        }
    }
    
    
    
    private func putChar(x:Int,y:Int,c:UInt8) {
        
        vram[y][x] = c
        
    }
    

    // lockFocusによるイメージ生成
    func vram2ImageLF() {
        
        var screenImage = NSImage(size: NSSize(width: self.width * 8,height: self.height * 8))

        screenImage.lockFocus()
        
        for y in 0..<height {
            let yp = (height - y) * 8
//            NSLog("y:\(y) yp:\(yp)")
            for x in 0..<width {
                
                let c:UInt8 = vram[y][x]

                let xp = x * 8
                let rect = NSRect(x: xp, y: yp, width: 8, height: 8)
                fontImage.drawInRect(rect,
                    fromRect: fontRectX(c),
                    operation: NSCompositingOperation.CompositeDestinationOver, fraction: 1.0)
                
            }
        }
        
        screenImage.unlockFocus()
        
        if let d = delegate {
            d.onDispChange(screenImage)
        }
    }
    
    func fontRectX(c8:UInt8) -> NSRect {
        let c = Int(c8)
        let low = c & 0xF
        let high = 15 - ((c & 0xF0) >> 4)
        return NSRect(x: low * 8, y: high * 8, width: 8, height: 8)
    }
    
    // Core Graphicsによるイメージ生成
    func vram2ImageCG() {
        let image = NSBitmapImageRep(data: fontImage.TIFFRepresentation!)?.CGImage!
        
        let widthBits = width * 8
        let heightBits = height * 8
        
        
        // 新しいサイズのビットマップを作成します。
        let bitsPerComponent = Int(8)
        let bytesPerRow = Int(4 * widthBits)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
        let bitmapContext = CGBitmapContextCreate(nil, widthBits, heightBits, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)!

//        CGContextSetRGBFillColor(bitmapContext, 1.0, 0.0, 0.0, 1.0);
//        CGContextSetRGBStrokeColor(bitmapContext, 0.0, 1.0, 0.0, 1.0);
//        CGContextFillRect(bitmapContext, NSRect(x: 0,y: 0,width: widthBits,height: heightBits));
        
        for y in 0..<height {
            let yp =  (height - y - 1)  * 8
            for x in 0..<width {
                
                let c:UInt8 = vram[y][x]
                
                let xp = x * 8
                let rect = NSRect(x: xp, y: yp, width: 8, height: 8)

                let fontref = CGImageCreateWithImageInRect(image, fontRect(c));

                CGContextDrawImage(bitmapContext, rect, CGImageCreateCopy( fontref))
            }
        }

        // ビットマップを NSImage に変換します。
        let newImageRef = CGBitmapContextCreateImage(bitmapContext)!
        let newImage = NSImage(CGImage: newImageRef, size: NSSize(width: widthBits, height: heightBits))

        if let d = delegate {
            d.onDispChange(newImage)
        }
    }

    func fontRect(c8:UInt8) -> NSRect {
        let c = Int(c8)
        let low = c & 0xF
        let high = ((c & 0xF0) >> 4)
        return NSRect(x: low * 8, y: high * 8, width: 8, height: 8)
    }
    

    func takeImage() {
        vram2ImageCG()
    }
    
}

