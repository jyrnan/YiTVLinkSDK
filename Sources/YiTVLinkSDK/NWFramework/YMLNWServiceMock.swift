//
//  YMLNWServiceMock.swift
//  YiTVLinkSDK
//
//  Created by jyrnan on 2023/1/12.
//

import Foundation
import Network

class YMLNWServiceMock: YMLNWServiceProtocol, YMLNWConnectionDelegate, YMLNWListenerDelegate {
    func ListenerReady() {
        
    }
    
    func ListenerFailed() {
        
    }
    
    func connectionReady(connection: YMLNWConnection) {
        
    }
    
    func connectionFailed(connection: YMLNWConnection) {
        
    }
    
    func receivedMessage(content: Data?, connection: YMLNWConnection) {
        
    }
    
    func displayAdvertizeError(_ error: NWError) {
        
    }
    
    func connectionError(connection: YMLNWConnection, error: NWError) {
        
    }
    

    var tcpClient: YiTVLinkSDK.YMLNWConnection?
    var udpClient: YiTVLinkSDK.YMLNWConnection?
    lazy var searchUdpClient: YMLNWConnection! = YMLNWConnection(endpoint: NWEndpoint.hostPort(host: .init("127.0.0.1"),
                                                                                              port: .init(rawValue:8889)!),
                                                                delegat: self)
    lazy var udpListener: YMLNWListener! = .init(on: 6044, delegate: self)
    var lisener: YiTVLinkSDK.YMLListener?
    
    var discoveredDevice: [YiTVLinkSDK.DiscoveryInfo] = []
    var hasConnectedToDevice: YiTVLinkSDK.DeviceInfo?
    
    func initSDK(key: String) {}
    
    func searchDeviceInfo(searchListener: YiTVLinkSDK.YMLListener) {
        lisener = searchListener
        guard discoveredDevice.isEmpty else { return }
        let devices = [DeviceInfo.sample, DeviceInfo.sample, DeviceInfo.sample, DeviceInfo.sample]
        discoveredDevice = devices.map { DiscoveryInfo(device: $0, TcpPort: 0, UdpPort: 0) }
        lisener?.deliver(devices: [DeviceInfo.sample, DeviceInfo.sample, DeviceInfo.sample, DeviceInfo.sample])
    }
    
    func createTcpChannel(info: YiTVLinkSDK.DeviceInfo) -> Bool {
        lisener?.notified(with: "TCPCONNECTED")
        return true
    }
    
    func sendTcpData(data: Data) {
        lisener?.notified(with: "Data sent: \(data)")
    }
    
    func receiveTcpData(TCPListener: YiTVLinkSDK.YMLListener) {
        lisener = TCPListener
    }
    
    func closeTcpChannel() {
        tcpClient = nil
        lisener?.notified(with: "TCPDISCONNECTED")
    }
    
    func createUdpChannel(info: YiTVLinkSDK.DeviceInfo) -> Bool {
        return true
    }
    
    func sendGeneralCommand(command: RemoteControl) -> Bool {
        lisener?.notified(with: "Genneral command sent: \(command)")
        return true
    }
    
    func modifyDeviceName(name: String) {}
    
    private func echo(data: Data) {
        lisener?.deliver(data: data)
    }
}
