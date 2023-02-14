//
//  YMLNetworkProtocol.swift
//  YiTVLinkSDK
//
//  Created by jyrnan on 2022/12/15.
//

import Foundation

protocol YMLNetworkProtocol: AnyObject {
    func initSDK(key: String)
    func searchDeviceInfo(searchListener: YMLListener)
    func createTcpChannel(info: DeviceInfo) -> Bool
    func sendTcpData(data: Data)
    func receiveTcpData(TCPListener: YMLListener)
    func closeTcpChannel()
    func createUdpChannel(info: DeviceInfo) -> Bool
    func sendGeneralCommand(command: RemoteControl) -> Bool
    func modifyDeviceName(name: String)
}

