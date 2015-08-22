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
    
    /*
    CLS 19, 12
    SCROLL 左　21, 28
    SCROLL 右　21, 29
    SCROLL 上　21, 30
    SCROLL 下　21, 31
    LOCATE 21, 32+X,32+Y
    */
    
    func interpret(str:[UInt8]) {
        for c in str {
            switch interpreterState {
            case .TakeX:
                switch c {
                case 28:
                    // スクロール左
                    scrollLeft()
                    interpreterState = .Idle
                    vram2ImageCG()
                    break
                case 29:
                    // スクロール右
                    scrollRight()
                    interpreterState = .Idle
                    vram2ImageCG()
                    break
                case 30:
                    // スクロール上
                    scrollUp()
                    interpreterState = .Idle
                    vram2ImageCG()
                    break
                case 31:
                    // スクロール下
                    scrollDown()
                    interpreterState = .Idle
                    vram2ImageCG()
                    break
                    
                default:
                    cursorX = Int(c) - 32
                    
                    if cursorX < 0 {
                        NSLog("invalid cursorX:\(cursorX)")
                        cursorX = 0
                        interpreterState = .Idle
                    } else {
                        interpreterState = .TakeY
                    }
                    break
                }
                
                
                break
                
            case .TakeY:
                cursorY = Int(c) - 32
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
        if x < 0 {
            NSLog("invalid x:\(x)")
        }
        if y < 0 {
            NSLog("invalid y:\(y)")
        }
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
    
    func scrollLeft() {
        for y in 0..<height {
            for x in 0..<(width - 1) {
                vram[y][x] = vram[y][x+1]
            }
            vram[y][width - 1] = 32
        }
    }

    func scrollRight() {
        for y in 0..<height {
            for var x = (width - 1); x > 0; x-- {
                vram[y][x] = vram[y][x-1]
            }
            vram[y][0] = 32
        }
    }
    
    func scrollUp() {
        for y in 0..<(height - 1) {
            for x in 0..<width  {
                vram[y][x] = vram[y+1][x]
            }
        }
        for x in 0..<width  {
            vram[height - 1][x] = 32
        }
    }

    func scrollDown() {
        for var y = (height - 1); y > 0; y-- {
            for x in 0..<width  {
                vram[y][x] = vram[y-1][x]
            }
        }
        for x in 0..<width  {
            vram[0][x] = 32
        }
    }


    func takeImage() {
        vram2ImageCG()
    }
    
}

