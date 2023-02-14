//
//  DiscoveryInfo.swift
//  YiTVLinkSDK
//
//  Created by jyrnan on 2022/11/15.
//

import Foundation

public class DiscoveryInfo: NSObject, Codable {
    override public var description: String {
        return super.description + "\n" + "发现设备：\(device.description)\n\nTcpPort:\(tcpPort)\nUdpPort:\(udpPort)"
    }
    
    @objc public var device: DeviceInfo
    @objc public var tcpPort: UInt16
    @objc public var udpPort: UInt16
   
    @objc public var encodeData: String = ""
    @objc public var codeString: String = ""
    
    @objc public var cmd: Int = 0x70
    
    
   
   @objc public init(device: DeviceInfo, TcpPort: UInt16, UdpPort: UInt16) {
       self.device = device
       self.tcpPort = TcpPort
       self.udpPort = UdpPort
   }
    
    static var sample: DiscoveryInfo {
        return DiscoveryInfo.init(device: DeviceInfo.localMockServer, TcpPort: 0, UdpPort: 0)
    }
}
