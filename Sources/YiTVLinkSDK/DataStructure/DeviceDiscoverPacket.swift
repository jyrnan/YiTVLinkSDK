//
//  File.swift
//  
//
//  Created by jyrnan on 2023/3/17.
//

import Foundation

struct DeviceDiscoverPacket: EncodedDatable {
  
  enum Platform: UInt16, UInt16RawValue {
    case TV = 0x02ff
    case mobile_android     = 0x0100
    case mobile_iOS         = 0x0101
    case mobile_windows     = 0x0102
    case PC                 = 0x0200
    case SetTop_Box         = 0x0210
    case secondary_Display  = 0x0202
    
  }
  
  let packetCMD: UInt16         = 0x0070
  let service_id: UInt32        = 0x0000_0000
  let protocol_version: UInt16  = 0x0009
  let dev_type:Platform         = .mobile_iOS
  let dev_name:String
}
