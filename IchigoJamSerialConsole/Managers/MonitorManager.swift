//
//  MonitorManager.swift
//  IchigoJamSerialConsole
//
//  Created by titoi2 on 2015/08/18.
//  Copyright (c) 2015年 titoi2. All rights reserved.
//

import Foundation
import Cocoa

class MonitorManager {
    
    var width:Int
    var height:Int
    var cursorX:Int = 0
    var cursorY:Int = 0
    
    var vram:[[UInt8]]
    var screenImage: NSImage
    
    var state:State
    var fontImage:NSImage = NSImage(named: "ichigo_chars")!
    
    init(w:Int, h:Int) {
        width = w;
        height = h;
        vram = [[UInt8]](count: h, repeatedValue: [UInt8](count: w, repeatedValue: 0))
        state = State.Normal
        
        screenImage = NSImage(size: NSSize(width: self.width * 8,height: self.height * 8))
        
    }
    
    
    
    enum State {
        case Normal
        case TakeX
        case TakeY
    }
    
    func interpret(str:[UInt8]) {
        for c in str {
            switch state {
            case .TakeX:
                cursorX = Int(c)
                state = .TakeY
                break
                
            case .TakeY:
                cursorY = Int(c)
                state = .Normal
                break
                
            default:
                switch c {
                case 0x10:
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
                    break
                    
                case 0x13:
                    cursorX = 0
                    cursorY = 0
                    break
                    
                case 0x15:
                    state = .TakeX
                    break
                    
                default:
                    putChar( cursorX, y: cursorY, c: c)
                    
                    cursorX++
                    if cursorX >= width {
                        cursorX = 0
                    }
                }
                
            }
        }
    }
    

    func putChar(x:Int,y:Int,c:UInt8) {
        vram[y][x] = c

    }

}

