//
//  YMLNetwork.swift
//  YiTVLinkSDK
//
//  Created by jyrnan on 2022/12/15.
//

import Foundation

public class YMLNetwork: NSObject, YMLNetworkProtocol {
    // MARK: - Types
    
    struct Status {
        private(set) var value: String
        init(_ value: String) {
            self.value = value
        }
        static let TCPConnected = Status("TCPCONNECTED")
        static let TCPDisconnected = Status("TCPDISCONNECTED")
        static let UDPConnected = Status("UDPCONNECTED")
        static let UDPDisconnected = Status("UDPDISCONNECTED")
    }


    // 通过广播进行设备发现的UDP接收端口
    static let DEV_DISCOVERY_UDP_PORT: UInt16 = 10691
    
    typealias SuccessHandler = (Data) -> Void
    typealias FailureHandler = (Error?) -> Void
    typealias StatusHandler = (YMLNetwork.Status) -> Void

    // MARK: - Properties

    // 模拟数据实例
    @objc public static let mock = YMLNetwork(service: YMLNWServiceMock())
    @objc public static let shared = YMLNetwork(service: YMLNWService())
    
    var service: YMLNWServiceProtocol = YMLNWService()

    // MARK: - Initializers

    private init(service: YMLNWServiceProtocol) {
        self.service = service
    }
    
    override init() {}
    
    // MARK: - APIs

    @objc public func initSDK(key: String) {
        service.initSDK(key: key)
    }
    
    @objc public func searchDeviceInfo(searchListener: YMLListener) {
        service.searchDeviceInfo(searchListener: searchListener)
    }
    
    @objc public func createTcpChannel(info: DeviceInfo) -> Bool {
        return service.createTcpChannel(info: info)
    }
    
    @objc public func sendTcpData(data: Data) {
        service.sendTcpData(data: data)
    }
    
    @objc public func receiveTcpData(TCPListener: YMLListener) {
        service.receiveTcpData(TCPListener: TCPListener)
    }
    
    @objc public func closeTcpChannel() {
        service.closeTcpChannel()
    }
    
    @objc public func createUdpChannel(info: DeviceInfo) -> Bool {
        return service.createUdpChannel(info: info)
    }
    
    @objc public func sendGeneralCommand(command: RemoteControl) -> Bool {
        return service.sendGeneralCommand(command: command)
    }
    
    @objc public func modifyDeviceName(name: String) {
        service.modifyDeviceName(name: name)
    }
}

extension YMLNetwork {
    
}
