//
//  File.swift
//  
//
//  Created by jyrnan on 2023/3/29.
//

import Foundation

public struct PlayMediaFilePacket: EncodedDatableProtocol {
  public enum nextFlag: UInt32, FourBytesRawValue {
    case no   = 0
    case yes  = 1
  }
  let packetCMD: UInt16         = 0x2001
  let file_size: UInt32
  let have_next_flag: nextFlag
  let local_ip: LocalIP
  let file_name: String
  
  public init(file_size: UInt32, have_next_flag: nextFlag, local_ip: String?, file_name: String) {
    self.file_size = file_size
    self.have_next_flag = have_next_flag
    self.local_ip = LocalIP(ip: local_ip ?? "")
    self.file_name = file_name
  }
}
