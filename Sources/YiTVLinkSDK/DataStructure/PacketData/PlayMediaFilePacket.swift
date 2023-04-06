//
//  File.swift
//  
//
//  Created by jyrnan on 2023/3/29.
//

import Foundation

//2.8  业务相关协议包定义

// 2.8.2  一个连接活动命令包
struct HeartBeat: EncodedDatableProtocol {
  let packetCMD: UInt16         = 0x1000
}

// 2.8.3  一个连接活动应答命令包
struct EchoHeartBeat:EncodedDatableProtocol {
  let packetCMD: UInt16         = 0x4001
}

// 2.8.4  一个播放状态回传应答包


// 2.8.5
public struct PlayMediaFilePacket: EncodedDatableProtocol {
  public init() {
    
  }
  
  public enum nextFlag: UInt32, FourBytesRawValue {
    case no   = 0
    case yes  = 1
  }
  var packetCMD: UInt16         = 0x2001
  var file_size: UInt32         = 0x0000_0000
  var have_next_flag: nextFlag  = .no
  var local_ip: LocalIP = LocalIP(ip: "")
  var file_name: String = ""
  
  public init(file_size: UInt32, have_next_flag: nextFlag, local_ip: String?, file_name: String) {
    self.file_size = file_size
    self.have_next_flag = have_next_flag
    self.local_ip = LocalIP(ip: local_ip ?? "")
    self.file_name = file_name
  }
}
