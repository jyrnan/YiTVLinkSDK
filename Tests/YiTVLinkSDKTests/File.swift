//
//  File.swift
//  
//
//  Created by jyrnan on 2023/3/19.
//

import Foundation
enum TestUtility {
  static func makeRandomValidPort() -> UInt16 {
    let minPort = UInt32(1024)
    let maxPort = UInt32(UINT16_MAX)
    let value = maxPort - minPort + 1
    return UInt16(minPort + arc4random_uniform(value))
  }
}
