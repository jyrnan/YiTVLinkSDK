//
//  YMLNWConnection.swift
//  DemoNetworkApp
//
//  Created by jyrnan on 2023/1/17.
//

import Foundation
import Network
import os.log

protocol YMLNWConnectionDelegate: AnyObject {
  func connectionReady(connection: YMLNWConnection)
  func connectionFailed(connection: YMLNWConnection)
  func receivedMessage(content: Data?, connection: YMLNWConnection)
  func displayAdvertiseError(_ error: NWError)
  func connectionError(connection: YMLNWConnection, error: NWError)
}

enum PeerType: String, CustomStringConvertible {
  var description: String { rawValue }
    
  case udp
  case tcp
  case tls // 支持bonjour发现和PSK的tls连接
}

class YMLNWConnection {
  // MARK: - Properties

  weak var delegate: YMLNWConnectionDelegate?
    
  var connection: ConnectionProtocol?
  let endPoint: NWEndpoint?
  let id: UUID = .init()
      
  // 以连接ip和端口号作为该连接的名字，连接准备就绪时会修改成ip和端口号
  var name: String = ""
    
  // 标识连接类型
  var type: PeerType = .tcp
    
  // 预设连接的类型参数
  var parameters: NWParameters = .tcp
    
  // 标记连接是主动发起连接还是被动接入连接
  let initiatedConnection: Bool
    
  var heartbeatTimer: Timer?
    
  let log = OSLog(subsystem: "com.et.YiTVLinkSDK", category: "YMLNWConnection")
    
  // MARK: - inits
    
  // 创建主动发起的连接，根据连接类型创建不支持SSL的udp或tcp连接
  init(endpoint: NWEndpoint, delegate: YMLNWConnectionDelegate, type: PeerType = .tcp) {
    self.delegate = delegate
    self.endPoint = endpoint
    self.type = type
        
    if case .udp = type {
      parameters = .udp
      parameters.requiredLocalEndpoint = NWEndpoint.hostPort(host: NWEndpoint.Host("0.0.0.0"), port: NWEndpoint.Port(rawValue: YMLNetwork.DEV_DISCOVERY_UDP_LISTEN_PORT)!)
      parameters.requiredInterfaceType = .wifi
      parameters.allowLocalEndpointReuse = true
    }
    
    let connection = NWConnection(to: endpoint, using: parameters)
    self.connection = connection
    self.initiatedConnection = true

    startConnection()
  }
    
  // 创建主动发起tcpSSL，支持bonjour的连接。设置网络途径(interface)，passcode用来创建tls连接
  init(endpoint: NWEndpoint, interface: NWInterface?, passcode: String, delegate: YMLNWConnectionDelegate) {
    self.delegate = delegate
    self.endPoint = endpoint
    self.type = .tls
        
    let connection = NWConnection(to: endpoint, using: passcode == "" ? .tcp : NWParameters(passcode: passcode))
    self.connection = connection
    self.initiatedConnection = true

    startConnection()
  }
    
  // 创建收到连接请求时候的被动接入连接
  init(connection: NWConnection, delegate: YMLNWConnectionDelegate) {
    self.delegate = delegate
    self.endPoint = nil

    self.connection = connection
    self.initiatedConnection = false
        
    startConnection()
  }
    
  // MARK: - Start and stop
    
  func cancel() {
    if let connection = connection {
      connection.cancel()
      self.connection = nil
    }
  }
    
  // 针对发起和接入两种连接进行启动相关设置
  // 该方法主要设置stateUpdateHandler用来处理NWConnection各种状态
  // 并设置NWConnection启动
  func startConnection() {
    guard let connection = connection else { return }
        
    connection.stateUpdateHandler = { [weak self] newState in
      guard let self = self else { return }
            
      switch newState {
      case .ready:
        self.name = connection.endpoint.debugDescription
        print("\(connection) established")
        os_log("established", log: self.log)
        
        // 如果准备就绪就开始接收消息
        self.setReceive()
                
        // TODO: - 需要修改：如果是UDP则通知代理已经准备好，TCP需要在握手完成后才通知
        if let delegate = self.delegate {
          delegate.connectionReady(connection: self)
        }
            
      case .failed(let error):
        print("\(connection) failed with \(error)")
                
        // 因为错误调用取消方法来中断连接
        connection.cancel()
                
        // 依据情况决定是否重新连接,条件：如果是主动发起连接，并且错误是对方
        if let endPoint = self.endPoint,
           self.initiatedConnection,
           error == NWError.posix(.ECONNABORTED)
        {
          // 符合条件的话重新创建连接
          let connection = NWConnection(to: endPoint, using: self.parameters)
          self.connection = connection
          self.startConnection()
        } else if let delegate = self.delegate {
          // 通知代理连接已经断开
          delegate.connectionFailed(connection: self)
        }
      case .cancelled:
        self.delegate?.connectionFailed(connection: self)
      default:
        break
      }
    }
        
    // TODO: - 可以设置更灵活的queue
    connection.start(queue: DispatchQueue.global())
        
    startHeartbeat()
  }
    
  // MARK: - Send
    
  // 设置发送消息，这里其实包括了三类形式：UDP直接发送， TLS下采用自定义形式，TCP下采用通用的封包方式
  func send(content: Data) {
    guard let connection = connection else { return }
        
    // 如果是UDP连接协议，则采用这部分的接收方法
    if case .udp = type {
      connection.send(content: content, contentContext: .defaultMessage, isComplete: true, completion: .contentProcessed { [weak self] error in
        guard let self = self else { return }
                
        if let error = error {
          self.delegate?.connectionError(connection: self, error: error)
        } else {
          print("Send \(content.count) bytes")
        }
      })
            
      return
    }
        
    // 如果是SSL连接协议，则采用这部分的接收方法
    // 这部分对于数据处理采用了NWProtocolFramer协议
    // 设置发送消息，可以参考 sendMove(_ move: String)
    if case .tls = type {
      // 先创建NWProtocolFramer.Message，主要是内容是message的type
      let message = NWProtocolFramer.Message(YMLNWMessageType: .data)
      // 将message放置在metaData中，来创建context
      let context = NWConnection.ContentContext(identifier: "Data", metadata: [message])
      // 通过connection发送时候带上context参数，isComplete设置成true
      connection.send(content: content, contentContext: context, isComplete: true, completion: .idempotent)
            
      return
    }
        //TODO: - TCP发送的方式究竟是否需要添加包头？
    // 下面的代码暂时不需要了，因为包头会在应用层添加
    // 如果是TCP连接协议，数据采用加入长度头的封包方法，这是通用的封包方法
    // 获取后续包长度，需要加上类型长度2
    var sizePrefix = withUnsafeBytes(of: UInt16(content.count).bigEndian) { Data($0) }
    // 包长度数据后添加包类型数据
    sizePrefix.append(contentsOf: [0x30, 0x04])
        
    print("Send \(content.count) bytes")
        //TODO: - 这个方法里面的isComplete要设置成false，否则会断开连接。
    connection.batch {
//      connection.send(content: sizePrefix, contentContext: .defaultMessage, isComplete: false, completion: .contentProcessed { [weak self] error in
//        guard let self = self else { return }
//        if let error = error {
//          self.delegate?.connectionError(connection: self, error: error)
//        }
//      })
      connection.send(content: content, contentContext: .defaultMessage, isComplete: false, completion: .contentProcessed { [weak self] error in
        guard let self = self else { return }
        if let error = error {
          self.delegate?.connectionError(connection: self, error: error)
        }
      })
    }
  }
    
  func registerACKHandler(data: Data) {
    let registACKData = makeRegisterACKPack(data: data)
    connection?.send(content: registACKData, contentContext: .defaultMessage, isComplete: true, completion: .contentProcessed { [weak self] error in
      guard let self = self else { return }
            
      if let error = error {
        self.delegate?.connectionError(connection: self, error: error)
      }
            
      // 通知代理已经准备好
      if let delegate = self.delegate {
        delegate.connectionReady(connection: self)
      }
    })
  }
    
  func makeRegisterACKPack(data: Data) -> Data {
    var sendPack = Data(capacity: 4)
    var length = UInt16(data.count + 2).bigEndian
    let packLengthData = Data(bytes: &length, count: MemoryLayout.size(ofValue: length))
        
    sendPack.append(packLengthData)
    sendPack.append(contentsOf: [0x00, 0x03])
    sendPack.append(data)
        
    return sendPack
  }

  // MARK: - Receive
    
  func setReceive() {
    switch type {
    case .tcp:
      receiveByStream()
    case .udp:
      receiveByMessage()
    case .tls:
      receiveByYMLNWMessage()
    }
  }
    
  // 设置接收消息，转交给代理，并接受下一个消息 主要用于UDP？
  func receiveByMessage() {
    guard let connection = connection else { return }
        
    connection.receiveMessage { content, _, _, error in
            
      if let data = content, !data.isEmpty {
        print("\(connection.endpoint.debugDescription) recieve \(data.count) bytes")
        self.delegate?.receivedMessage(content: content, connection: self)
      }
            
      if let error = error {
        self.delegate?.connectionError(connection: self, error: error)
      } else {
        // 继续处理下一个消息
        self.receiveByMessage()
      }
    }
  }
    
  // 设置接收指定字节数据，主要用于TCP？
  func receiveByStream() {
    connection?.receive(minimumIncompleteLength: MemoryLayout<UInt16>.size, maximumLength: MemoryLayout<UInt16>.size) { content, context, isComplete, error in
      var sizePrefix: UInt16 = 0
            
      // 解码获取body长度值
      if let data = content, !data.isEmpty {
        sizePrefix = data.withUnsafeBytes { ptr in
          ptr.bindMemory(to: UInt16.self)[0].bigEndian
        }
        
        sizePrefix += 2 // 需要在body长度加上CMD的2个字节
      }
            
      if isComplete {
        self.cancel()
      }
            
      if let error = error {
        self.delegate?.displayAdvertiseError(error)
      } else {
        // 获得数据包长度，继续调用方法获得该长度的数据
        self.connection?.receive(minimumIncompleteLength: Int(sizePrefix), maximumLength: Int(sizePrefix)) { content, context, isComplete, error in
          if let data = content, !data.isEmpty {
            let message = String(data: data, encoding: .utf8)
            let logMessage = "TCP connection did receive, data: \(data as NSData) string: \(message ?? "-")  ip: \(self.name) context:\(String(describing: context?.identifier))"
            print(#line, logMessage)
                        
            let typeHead = Array(data[0 ... 1])
//            let remainData = data[2...]
            switch typeHead {
            case [0x40, 0x01]:break
//              print(#line, "收到心跳包")
//            case [0x00, 0x02]:
//              self.registerACKHandler(data: remainData)
            case [0x01, 0x00]:
              let remainData = data.dropFirst(2)
              if !remainData.isEmpty {
                self.delegate?.receivedMessage(content: remainData, connection: self)}

            default:
              break
            }
          }
                    
          if isComplete {
            self.cancel()
          }
                    
          if let error = error {
            self.delegate?.connectionError(connection: self, error: error)
          } else {
            // 继续处理下一个消息
            self.receiveByStream()
          }
        }
      }
    }
  }
    
  // 设置通过PeerMessage来实现收发，用于SSL
  func receiveByYMLNWMessage() {
    guard let connection = connection else { return }
        
    connection.receiveMessage { content, context, _, error in
      if let message = context?.protocolMetadata(definition: YMLNWProtocol.definition) as? NWProtocolFramer.Message {
        self.delegate?.receivedMessage(content: content, connection: self)
      }
            
      if error == nil {
        self.receiveByYMLNWMessage()
      }
    }
  }
    
  // MARK: - Heartbeat
    
  func startHeartbeat() {
    guard initiatedConnection, case .tcp = type else { return }
        
    heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { _ in
      self.sendHeartbeat()
    })
        
    heartbeatTimer?.fire()
  }
    
  private func sendHeartbeat() {
    guard let connection = connection else { return }
        
    let timestamp = Date()
    let content: Data = Data([UInt8](arrayLiteral: 0x00, 0x00, 0x10, 0x00))
    
    let message = NWProtocolFramer.Message(YMLNWMessageType: .heart)
    let context = NWConnection.ContentContext(identifier: "heartbeat", metadata: [message])
        
//    connection.send(content: content, contentContext: context, isComplete: true, completion:  .idempotent)
    send(content: content)
  }
}

extension YMLNWConnection: Identifiable {}

extension YMLNWConnection: Hashable {
  static func == (lhs: YMLNWConnection, rhs: YMLNWConnection) -> Bool {
    return lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}


extension NWConnection: ConnectionProtocol {}

protocol ConnectionProtocol: AnyObject {
  var state: NWConnection.State { get }
  var endpoint: NWEndpoint {get}
  var stateUpdateHandler: ((_ state: NWConnection.State) -> Void)? {set get}
  func send(content: Data?, contentContext: NWConnection.ContentContext, isComplete: Bool, completion: NWConnection.SendCompletion)
  func receiveMessage(completion: @escaping (_ completeContent: Data?, _ contentContext: NWConnection.ContentContext?, _ isComplete: Bool , _ error: NWError?) -> Void)
  func receive(minimumIncompleteLength: Int, maximumLength: Int, completion: @escaping (_ content: Data?, _ contentContext: NWConnection.ContentContext?, _ isComplete: Bool, _ error: NWError?) -> Void)
  func batch(_ block: () -> Void)
  func start(queue: DispatchQueue)
  func cancel()
}

class MockConnection: ConnectionProtocol {
  let endpoint: NWEndpoint
  var stateUpdateHandler: ((_ state: NWConnection.State) -> Void)?
  var state: NWConnection.State = .ready
  var receiveData: Data?
  
  var cancelWasCalled: Bool = false
  var startWasCalled:Bool = false
  
  init(endpoint: NWEndpoint) {
    self.endpoint = endpoint
  }
  func send(content: Data?, contentContext: NWConnection.ContentContext = .defaultMessage, isComplete: Bool = true, completion: NWConnection.SendCompletion) {
    receiveData = content
  }
  
  func receiveMessage(completion: @escaping (_ completeContent: Data?, _ contentContext: NWConnection.ContentContext?, _ isComplete: Bool, _ error: NWError?) -> Void){
    
  }
  func receive(minimumIncompleteLength: Int, maximumLength: Int, completion: @escaping (_ content: Data?, _ contentContext: NWConnection.ContentContext?, _ isComplete: Bool, _ error: NWError?) -> Void){
    
  }
  func batch(_ block: () -> Void){
    
  }
  func start(queue: DispatchQueue){
    startWasCalled = true
  }
  func cancel(){
    cancelWasCalled = true
  }
}

