//
//  RemoteControl.swift
//  YiTVLinkSDK
//
//  Created by jyrnan on 2023/1/5.
//

import Foundation

public class RemoteControl: NSObject, Codable {
    
    @objc public enum TYPE: Int, Codable {
        case CTRL_TYPE_KEY = 0x1001
        case CTRL_TYPE_IRKEY = 0x1003
        case CTRL_TYPE_MOUSE = 0x1004
    }
    
    @objc public var cmd: TYPE = .CTRL_TYPE_IRKEY
    @objc public var keyData: KEYData?
    @objc public var keyCode: Int
    
    @objc public init(cmd: TYPE, keyData: KEYData? = nil, keyCode: Int = 0) {
        self.cmd = cmd
        self.keyData = keyData
        self.keyCode = keyCode
    }
    
    static let sample = RemoteControl(cmd: .CTRL_TYPE_MOUSE,
                                      keyData: KEYData())
   @objc public var data: Data? {
        return try? JSONEncoder().encode(self)
    }
}
