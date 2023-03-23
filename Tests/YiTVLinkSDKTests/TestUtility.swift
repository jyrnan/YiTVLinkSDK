//
//  File.swift
//  
//
//  Created by jyrnan on 2023/3/19.
//

import Foundation
import Network
@testable import YiTVLinkSDK


enum TestUtility {
  static func makeRandomValidPort() -> UInt16 {
    let minPort = UInt32(1024)
    let maxPort = UInt32(UINT16_MAX)
    let value = maxPort - minPort + 1
    return UInt16(minPort + arc4random_uniform(value))
  }
}

struct TestData: EncodedDatableProtocol {
  let packetCMD: UInt16         = 0xffff
  let testFiled: UInt16         = 0x0101
  let string: String            = "TestData"
}

extension NWError {
  static var sampleTestError: Self {NWError.posix(POSIXErrorCode(rawValue: EPROTO)!)}
}
