//
//  MockServerNW.swift
//  YiTVLinkSDKTests
//
//  Created by jyrnan on 2022/12/26.
//


import Foundation
import YiTVLinkSDK
import XCTest

class MockServerNW: NSObject {
    
    typealias Callback = Optional<() -> Void>
    var udpServer: UDPServer?
    var tcpServer: Server?
    
    var tcpPort: UInt16
    var udpPort: UInt16
      
    init(tcpPort: UInt16, udpPort: UInt16) {
        self.tcpPort = tcpPort
        self.udpPort = udpPort
    }
    
    func setupTcpServer() -> Bool {
        tcpServer = Server(port: tcpPort)
        do {
            try tcpServer?.start()
        } catch {
            XCTFail("Mockserver TCP start failed")
        }
        return true
    }
    
    func setupUdpServer() -> Bool {
        udpServer = UDPServer(port: udpPort)
        do {
            try udpServer?.start()
        } catch {
            XCTFail("Mockserver UDP start failed")
        }
        return true
    }
    
    func closeUdp() {
        tcpServer = nil
        udpServer = nil
    }
    
    
    //MARK: - 数据处理
    
    /// 返回查找设备的数据
    func echoFoundDeviceData() -> Data {
        
        let mockDevice = DeviceInfo()
        mockDevice.devName = "mockDevice"
        
        let mockDescoveryInfo = DiscoveryInfo(device: mockDevice, TcpPort: tcpPort, UdpPort: udpPort)
        mockDescoveryInfo.cmd = 113
        
        let mockDescoveryInfoJson = try! JSONEncoder().encode(mockDescoveryInfo)
        
        return mockDescoveryInfoJson
    }
    
}

