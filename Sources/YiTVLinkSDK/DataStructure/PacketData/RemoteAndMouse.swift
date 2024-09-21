//
//  File.swift
//
//
//  Created by jyrnan on 2023/4/10.
//

import Foundation

// 2.7.2  一个遥控器按键事件命令包

public struct RCKeyPacket: EncodedDatableProtocol {
  public enum Key: UInt16, TwoBytesRawValue, CaseIterable {
    case rck_left = 105
    case rck_right = 106
    case rck_up = 103
    case rck_down = 108
    case rck_ok = 28
    case rck_voladd = 115
    case rck_volsub = 114
    // case rck_chlup
    // case rck_chldown
    case rck_home = 102
    case rck_back = 158
    case rck_power = 116
    case rck_source = 471
    case rck_menu = 139
    case rck_backspace = 14
    case keycode_yellow = 400
    case keycode_blue = 401
  }
  
  let packetCMD: UInt16 = 0x1003
  let key: UInt16
  
  ///增加一个init方法，可以实现既采用现有类型初始化
  ///又可以采用任意类型初始化
  public init(key: UInt16) {
    self.key = key
  }
  
  public init(key: Key) {
    self.key = key.rawValue
  }
}

// 2.7.3  一个鼠标事件命令包

public struct MouseEventPacket: EncodedDatableProtocol {
  public enum Motion: UInt8, OneByteRawValue {
    case move = 0x1
    case leftButtonPressed = 0x3
    case leftButtonReleased = 0x4
    case rightButtonPressed = 0x5
    case rightButtonReleased = 0x6
    case middleButtonPressed = 0x7
    case middleButtonReleased = 0x8
    case wheelVertically = 0x9
    case wheelHorizontally = 0xa
    case currentMouseOperation = 0xb
  }
  
  let packetCMD: Int16 = 0x1004
  let motion: Motion
  let x: Int16
  let y: Int16
  let w: Int16
  
  public init(motion: Motion, x: Int16, y: Int16, w: Int16) {
    self.motion = motion
    self.x = x
    self.y = y
    self.w = w
  }
}
