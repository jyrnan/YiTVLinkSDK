//
//  YMLNWService.swift
//  YiTVLinkSDK
//
//  Created by jyrnan on 2022/12/16.
//

import Foundation
import Network

@available(iOS 14.0, *)
class YMLNWService: NSObject, YMLNWServiceProtocol, YMLNWConnectionDelegate, YMLNWListenerDelegate {
  var serviceKey = "serviceKey"
    
  // MARK: - YMLNetworkProtocol

  var tcpClient: YMLNWConnection?
  var udpClient: YMLNWConnection?
    
  /// 发送设备搜索广播信息的UPD连接
  var searchUdpClient: YMLNWConnection!
  /// 接受设备搜索广播信息的UPD监听
  var udpListener: YMLNWListener!
    
  /// 应用提供回调
  weak var listener: YMLListener?
    
  /// 当前可以连接的设备信息
  var discoveredDevice: [DiscoveryInfo] = []
    
  /// 当前连接的设备
  var hasConnectedToDevice: DeviceInfo?
    
  init(listener: YMLListener? = nil) {
    print(#line, #function)

    super.init()
    setupSearchUdpClient()
    setupUdpListener()
//    setupGroup()
  }
    
  private func setupSearchUdpClient() {
    let host = NWEndpoint.Host("255.255.255.255")
    let port = NWEndpoint.Port(rawValue: YMLNetwork.DEV_DISCOVERY_UDP_PORT)!
    let endpoint = NWEndpoint.hostPort(host: host, port: port)
        
    let connection = YMLNWConnection(endpoint: endpoint, delegate: self, type: .broadcast)
      
    searchUdpClient = connection
  }
    
  private func setupUdpListener() {
    let port: UInt16 = YMLNetwork.DEV_DISCOVERY_UDP_LISTEN_PORT
    let listener = YMLNWListener(on: port, delegate: self, type: .udp)
    udpListener = listener
  }
  
  // MARK: - Testcode
  
   var groupConnection: NWConnectionGroup!
  private func setupGroup() {
    let multicastEndpoint = NWEndpoint.hostPort(host: NWEndpoint.Host("224.0.0.251"), port: NWEndpoint.Port(rawValue: 8000)!)
     
    let gd = try! NWMulticastGroup(for: [multicastEndpoint], disableUnicast: false)
      
    let con = NWConnectionGroup(with: gd, using: .udp)
    print(con)
    
    con.setReceiveHandler(rejectOversizedMessages: false, handler: { message, data, isComplete in
      if let data = data {
        print(#line, data, String(data: data, encoding: .utf8))
        let endpoint = message.remoteEndpoint?.debugDescription
        self.searchDeviceDataHandler(data: data, endpoint: endpoint)
      }
//      message.reply(content: "hello".data(using: .utf8))
      print("remote: ", message.remoteEndpoint)
      print("local: ", message.localEndpoint)
    })

    con.stateUpdateHandler = { state in
      switch state {
      case .ready:
        print("Group Ready")
          
      default:
        print("Group Down")
      }
    }
    
    con.start(queue: .main)
   
    groupConnection = con
  }
    
  // MARK: - YMLNetworkProtocol

  func initSDK(key: String) {
    serviceKey = key
  }
    
  func searchDeviceInfo(searchListener: YMLListener) {
    listener = searchListener
    searchDevice()
  }
    
  /// 创建到指定设备的TCP连接，这个方法会真正创建TCP连接
  /// - Parameter info: 要连接的设备信息
  /// - Returns: 连接创建是否成功
  func createTcpChannel(info: DeviceInfo) -> Bool {
    let host = NWEndpoint.Host(info.localIp)
    guard let port = NWEndpoint.Port(rawValue: getTcpPort(from: info)!) else { return false }
    let endPoint = NWEndpoint.hostPort(host: host, port: port)
    let connection = YMLNWConnection(endpoint: endPoint, delegate: self, type: .tcp)
    tcpClient = connection

    hasConnectedToDevice = info
    return tcpClient != nil
  }
    
  func sendTcpData(data: Data) {
    guard let client = tcpClient else { return }
        
    client.send(content: data)
  }
    
  /// 需要最先设置此方法来设置回调YMLListener
  /// - Parameter TCPListener: 回调YMLListener
  func receiveTcpData(TCPListener: YMLListener) {
    listener = TCPListener
  }
    
  func closeTcpChannel() {
    guard let client = tcpClient else { return }
        
    client.cancel()
  }
    
  func createUdpChannel(info: DeviceInfo) -> Bool {
    let host = NWEndpoint.Host(info.localIp)
    guard let port = NWEndpoint.Port(rawValue: getUdpPort(from: info)!) else { return false }
    let endPoint = NWEndpoint.hostPort(host: host, port: port)
    let connection = YMLNWConnection(endpoint: endPoint, delegate: self, type: .udp)
    udpClient = connection
       
    hasConnectedToDevice = info
    return true
  }
    
  func sendGeneralCommand(command rc: RemoteControl) -> Bool {
    let message = MessageWrapper(value: rc)
    guard let commandData = try? JSONEncoder().encode(message) else { return false }
    guard let client = udpClient else { return false }
    client.send(content: commandData)
    return true
  }
    
  func modifyDeviceName(name: String) {}
    
  // MARK: - YMLNWListenerDelegate
    
  func ListenerReady() {}
    
  func ListenerFailed() {}
    
  // MARK: - YMLNWConnectionDelegate
    
  func connectionReady(connection: YMLNWConnection) {
    switch connection.type {
    case .tcp:
      listener?.notified(with: "TCPCONNECTED")
    case .udp:
      listener?.notified(with: "UDPCONNECTED")
    default:
      break
    }
  }
    
  func connectionFailed(connection: YMLNWConnection) {
    switch connection.type {
    case .tcp:
      listener?.notified(with: "TCPDISCONNECTED")
    case .udp:
      listener?.notified(with: "UDPDISCONNECTED")
    default:
      break
    }
  }
    
  func receivedMessage(content: Data?, connection: YMLNWConnection) {
    guard let data = content else { return }
    switch connection.type {
    case .tcp:
      listener?.deliver(data: data)
    case .udp:
      let discoveryResponsePacketCMD: [UInt8] = [0x40, 0x70]
      if data.count > 12, Array(data[2...3]) == discoveryResponsePacketCMD {
        let endpoint = connection.connection?.endpoint.debugDescription
        searchDeviceDataHandler(data: data, endpoint: endpoint)
        break
      }
      listener?.deliver(data: data)
    default:
      break
    }
  }
    
  func displayAdvertiseError(_ error: NWError) {
    listener?.notified(error: error)
  }
    
  func connectionError(connection: YMLNWConnection, error: NWError) {
    listener?.notified(error: error)
  }
}

// MARK: - 设备查找

// TODO: - 需要按照旧版发送，并在接收到data后按照版本号解析body部分

extension YMLNWService {
  /// 发送广播获取局域网内电视信息
  func searchDevice() {
    print("Start search device...")
    let sendPack: Data = makeSearchDeviceSendPack()
    clearDiscoveredDevice()

    searchUdpClient.send(content: sendPack)
      
//    groupConnection.send(content: sendPack, completion: { error in

//      print(error?.debugDescription)
//      print(#line, #function, sendPack)
//    })
  }
    
  /// 创建并返回用于搜索局域网设备的UDP广播包
  /// - Parameter device: 发出搜寻包的设备信息
  /// - Returns:带有搜寻设备名称信息的广播包数据
  func makeSearchDeviceSendPack(with device: DeviceInfo? = nil) -> Data {
    let deviceDiscoveryData = DeviceDiscoverPacket(dev_name: "My iPhone").encodedData
    return deviceDiscoveryData
  }

  // TODO: - 需要按照旧协议进行解析
  /// 处理发送设备搜寻广播后收到的UDP数据
  /// - Parameters:
  ///   - data: 收到的UDP数据（默认加密）
  func searchDeviceDataHandler(data: Data, endpoint:String?) {
    print(#line, [UInt8](data))
    
    if let discoveredInfo = parseSearchResultData(data: data, endpoint:endpoint) {
      receiveOneDevice(info: discoveredInfo)
    }
  }

  private func parseSearchResultData(data: Data, endpoint:String?) -> DiscoveryInfo? {
    guard data.count > 12 else { return nil }
    
    let soft_version = UInt8(data[9])
    switch soft_version {
    case 1...8:
      // 旧版处理
      let dev_name = String(data: data[12...], encoding: .utf8) ?? "Unknown"
      let ip:String = String(endpoint?.split(separator: ":").first ?? "Unknown")
      let deviceInfo = DeviceInfo(devAttr: 0, name: dev_name, platform: "0", ip: ip, sdkVersion: "V\(soft_version).0.0")
      let discoveryInfo = DiscoveryInfo(device: deviceInfo, TcpPort: 8001, UdpPort: 8000)
      return discoveryInfo
      
    case 9:
      // 新版本处理方式
      let dev_info = data[12...]
      guard let discoveredInfo = try? JSONDecoder().decode(DiscoveryInfo.self, from: dev_info) else { return nil}
      return discoveredInfo
    
    default:
      break
    }
    return nil
  }
  
  private func receiveOneDevice(info: DiscoveryInfo) {
    print("--------- Technology research UDP did receive data \(info.device.description)-----------------")
        
    if !isContainsDevice(device: info.device) {
      addDiscovery(info: info)
                
      let devices = discoveredDevice.map(\.device)
      listener?.deliver(devices: devices)
    }
  }
    
  private func isContainsDevice(device: DeviceInfo) -> Bool {
    return discoveredDevice.map(\.device).contains {
      return device.localIp == $0.localIp && device.devName == $0.devName
    }
  }
    
  private func addDiscovery(info: DiscoveryInfo) {
    if !isContainsDevice(device: info.device) {
      discoveredDevice.append(info)
    }
  }
    
  private func clearDiscoveredDevice() {
    return discoveredDevice.removeAll()
  }
    
  private func getBroadcastIPAddr() -> String {
    guard let addressOfWifi = getWiFiAddress() else { return "255.255.255.255" }
    let broadcastIPAdd = addressOfWifi.split(separator: ".").dropLast().joined(separator: ".") + ".255"
// TODO: - package里面的debug标志会影响到这里返回值
#if TEST2
    print(#line, #function, "TEST")
    return "127.0.0.1"
#else
//        return broadcastIPAdd
//                return "192.168.1.106"
//                return "192.168.199.141"
//    return "192.168.31.158"
//                return "127.0.0.1"
//                return "224.0.0.251"
                return "255.255.255.255"
#endif
  }
}

extension YMLNWService {
  /// 获取本机Wi-Fi的IP地址
  /// - Returns: IP address of WiFi interface (en0) as a String, or `nil`
  private func getWiFiAddress() -> String? {
    var address: String?
            
    // Get list of all interfaces on the local machine:
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    if getifaddrs(&ifaddr) == 0 {
      var ptr = ifaddr
      while ptr != nil {
        let flags = Int32((ptr?.pointee.ifa_flags)!)
        var addr = ptr!.pointee.ifa_addr.pointee
                
        // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
        if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
          if addr.sa_family == UInt8(AF_INET) // || addr?.sa_family == UInt8(AF_INET6)
          {
            if String(cString: ptr!.pointee.ifa_name) == "en0" {
              // Convert interface address to a human readable string:
              var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
              if getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                             nil, socklen_t(0), NI_NUMERICHOST) == 0
              {
                address = String(validatingUTF8: hostname)
              }
            }
          }
        }
        ptr = ptr?.pointee.ifa_next
      }

      freeifaddrs(ifaddr)
    }
    return address
  }
}
