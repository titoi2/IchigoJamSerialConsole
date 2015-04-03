//
//  Utils.swift
//  IchigoJamSerialConsole
//
//  Created by titoi2 on 2015/04/02.
//  Copyright (c) 2015年 titoi2. All rights reserved.
//

import Foundation

// ファンクションキー定義
let FUNCTION_KEY_STR_01 = "CLS\u{0000A}"
let FUNCTION_KEY_STR_02 = "LOAD\u{0000A}"
let FUNCTION_KEY_STR_03 = "SAVE\u{0000A}"
let FUNCTION_KEY_STR_04 = "LIST\u{0000A}"
let FUNCTION_KEY_STR_05 = "RUN\u{0000A}"
let FUNCTION_KEY_STR_06 = "?FREE()\u{0000A}"
let FUNCTION_KEY_STR_07 = "OUT0\u{0000A}"
let FUNCTION_KEY_STR_08 = "VIDEO1\u{0000A}"



func str2UInt8Array(s:String) -> [UInt8]? {
    var buf:[UInt8] = []
    for c in s {
        let ucode:UInt32 = first(String(c).unicodeScalars)!.value
        let jcode = unicode2sjis(ucode)
        if jcode > 0 {
            buf.append(jcode)
        }
    }
    
    
    if buf.count == 0 {
        return nil
    }
    
    return buf
}

// unicodeポイントからShift-JISコードに変換、範囲外の文字は0を返す
func unicode2sjis(ucode:UInt32) -> UInt8 {
    if ucode < 0x80 {
        return UInt8(ucode)
    }

    var jcode : UInt8
    switch ucode {
    case 0xFF61: jcode = 0xA1   //。
    case 0xFF62: jcode = 0xA2   //「
    case 0xFF63: jcode = 0xA3   //」
    case 0xFF64: jcode = 0xA4   //、
    case 0xFF65: jcode = 0xA5   //・
    case 0xFF66: jcode = 0xA6   //ヲ
    case 0xFF67: jcode = 0xA7   //ァ
    case 0xFF68: jcode = 0xA8   //ィ
    case 0xFF69: jcode = 0xA9   //ゥ
    case 0xFF6A: jcode = 0xAA   //ェ
    case 0xFF6B: jcode = 0xAB   //ォ
    case 0xFF6C: jcode = 0xAC   //ャ
    case 0xFF6D: jcode = 0xAD   //ュ
    case 0xFF6E: jcode = 0xAE   //ョ
    case 0xFF6F: jcode = 0xAF   //ッ
    case 0xFF70: jcode = 0xB0   //
    case 0xFF71: jcode = 0xB1   //ア
    case 0xFF72: jcode = 0xB2   //イ
    case 0xFF73: jcode = 0xB3   //ウ
    case 0xFF74: jcode = 0xB4   //エ
    case 0xFF75: jcode = 0xB5   //オ
    case 0xFF76: jcode = 0xB6   //カ
    case 0xFF77: jcode = 0xB7   //キ
    case 0xFF78: jcode = 0xB8   //ク
    case 0xFF79: jcode = 0xB9   //ケ
    case 0xFF7A: jcode = 0xBA   //コ
    case 0xFF7B: jcode = 0xBB   //サ
    case 0xFF7C: jcode = 0xBC   //シ
    case 0xFF7D: jcode = 0xBD   //ス
    case 0xFF7E: jcode = 0xBE   //セ
    case 0xFF7F: jcode = 0xBF   //ソ
    case 0xFF80: jcode = 0xC0   //タ
    case 0xFF81: jcode = 0xC1   //チ
    case 0xFF82: jcode = 0xC2   //ツ
    case 0xFF83: jcode = 0xC3   //テ
    case 0xFF84: jcode = 0xC4   //ト
    case 0xFF85: jcode = 0xC5   //ナ
    case 0xFF86: jcode = 0xC6   //ニ
    case 0xFF87: jcode = 0xC7   //ヌ
    case 0xFF88: jcode = 0xC8   //ネ
    case 0xFF89: jcode = 0xC9   //ノ
    case 0xFF8A: jcode = 0xCA   //ハ
    case 0xFF8B: jcode = 0xCB   //ヒ
    case 0xFF8C: jcode = 0xCC   //フ
    case 0xFF8D: jcode = 0xCD   //ヘ
    case 0xFF8E: jcode = 0xCE   //ホ
    case 0xFF8F: jcode = 0xCF   //マ
    case 0xFF90: jcode = 0xD0   //ミ
    case 0xFF91: jcode = 0xD1   //ム
    case 0xFF92: jcode = 0xD2   //メ
    case 0xFF93: jcode = 0xD3   //モ
    case 0xFF94: jcode = 0xD4   //ヤ
    case 0xFF95: jcode = 0xD5   //ユ
    case 0xFF96: jcode = 0xD6   //ヨ
    case 0xFF97: jcode = 0xD7   //ラ
    case 0xFF98: jcode = 0xD8   //リ
    case 0xFF99: jcode = 0xD9   //ル
    case 0xFF9A: jcode = 0xDA   //レ
    case 0xFF9B: jcode = 0xDB   //ロ
    case 0xFF9C: jcode = 0xDC   //ワ
    case 0xFF9D: jcode = 0xDD   //ン
    case 0xFF9E: jcode = 0xDE   //
    case 0xFF9F: jcode = 0xDF   //
    default:
        jcode = 0
    }
    return jcode;
}


