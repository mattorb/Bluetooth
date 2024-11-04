//
//  Hexadecimal.swift
//  Bluetooth
//
//  Created by Alsey Coleman Miller on 3/2/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

internal extension FixedWidthInteger {
    
    func toHexadecimal() -> String {
        
        var string = String(self, radix: 16)
        while string.utf8.count < (MemoryLayout<Self>.size * 2) {
            string = "0" + string
        }
        return string.uppercased()
    }
}

internal extension Collection where Element: FixedWidthInteger {
    
    func toHexadecimal() -> String {
        let length = count * MemoryLayout<Element>.size * 2
        var string = ""
        string.reserveCapacity(length)
        string = reduce(into: string) { $0 += $1.toHexadecimal() }
        assert(string.count == length)
        return string
    }
}

internal extension UInt {
    
    init?(parse string: String, radix: UInt) {
        let digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        var result = UInt(0)
        for digit in string {
            #if hasFeature(Embedded)
            let character = digit
            #else
            let character = String(digit).uppercased().first!
            #endif
            if let stringIndex = digits.enumerated().first(where: { $0.element == character })?.offset {
                let val = UInt(stringIndex)
                if val >= radix {
                    return nil
                }
                result = result * radix + val
            } else {
                return nil
            }
        }
        self = result
    }
}

internal extension UInt16 {
    
    init?(hexadecimal string: String) {
        guard string.count == MemoryLayout<Self>.size * 2 else {
            return nil
        }
        #if hasFeature(Embedded) || DEBUG
        guard let value = UInt(parse: string, radix: 16) else {
            return nil
        }
        self.init(value)
        #else
        self.init(string, radix: 16)
        #endif
    }
}

internal extension UInt32 {
    
    init?(hexadecimal string: String) {
        guard string.count == MemoryLayout<Self>.size * 2 else {
            return nil
        }
        #if hasFeature(Embedded) || DEBUG
        guard let value = UInt(parse: string, radix: 16) else {
            return nil
        }
        self.init(value)
        #else
        self.init(string, radix: 16)
        #endif
    }
}

internal extension String.UTF16View.Element {
    
    // Convert 0 ... 9, a ... f, A ...F to their decimal value,
    // return nil for all other input characters
    func decodeHexNibble() -> UInt8? {
        switch self {
        case 0x30 ... 0x39:
            return UInt8(self - 0x30)
        case 0x41 ... 0x46:
            return UInt8(self - 0x41 + 10)
        case 0x61 ... 0x66:
            return UInt8(self - 0x61 + 10)
        default:
            return nil
        }
    }
}

internal extension [UInt8] {
    
    init?<S: StringProtocol>(hexadecimal string: S) {
        
        let str = String(string)
        let utf16: String.UTF16View
        if (str.count % 2 == 1) {
            utf16 = ("0" + str).utf16
        } else {
            utf16 = str.utf16
        }
        var data = [UInt8]()
        data.reserveCapacity(utf16.count / 2)
        
        var i = utf16.startIndex
        while i != utf16.endIndex {
            guard let hi = utf16[i].decodeHexNibble(),
                  let nxt = utf16.index(i, offsetBy:1, limitedBy: utf16.endIndex),
                  let lo = utf16[nxt].decodeHexNibble()
            else {
                return nil
            }
            
            let value = hi << 4 + lo
            data.append(value)
            
            guard let next = utf16.index(i, offsetBy:2, limitedBy: utf16.endIndex) else {
                break
            }
            i = next
        }
        
        self = data
        
    }
}
