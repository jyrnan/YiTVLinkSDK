//
//  YMLNWConnection.swift
//  DemoNetworkApp
//
//  Created by jyrnan on 2023/1/17.
//

import Foundation
import Network
import os.log

protocol ConnectionProtocol: AnyObject {
  var state: NWConnection.State { get }
  var endpoint: NWEndpoint { get }
  var stateUpdateHandler: ((_ state: NWConnection.State) -> Void)? { set get }
  var pathUpdateHandler: ((_ newPath: NWPath) -> Void)? {set get}
  
  func send(content: Data?, contentContext: NWConnection.ContentContext, isComplete: Bool, completion: NWConnection.SendCompletion)
  func receiveMessage(completion: @escaping (_ completeContent: Data?, _ contentContext: NWConnection.ContentContext?, _ isComplete: Bool, _ error: NWError?) -> Void)
  func receive(minimumIncompleteLength: Int, maximumLength: Int, completion: @escaping (_ content: Data?, _ contentContext: NWConnection.ContentContext?, _ isComplete: Bool, _ error: NWError?) -> Void)
  
  func start(queue: DispatchQueue)
  func cancel()
}

protocol YMLNWConnectionDelegate: AnyObject {
  func connectionReady(connection: YMLNWConnection)
  func connectionFailed(connection: YMLNWConnection)
  func receivedMessage(content: Data?, connection: YMLNWConnection)
  func connectionError(connection: YMLNWConnection, error: NWError)
}

enum PeerType: String, CustomStringConvertible {
  var description: String { rawValue }
    
  case udp
  case tcp
  case broadcast // 支持bonjour发现和PSK的tls连接
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
    }
        
    if case .broadcast = type {
      parameters = .udp
      parameters.requiredLocalEndpoint = NWEndpoint.hostPort(host: NWEndpoint.Host("0.0.0.0"), port: NWEndpoint.Port(rawValue: YMLNetwork.DEV_DISCOVERY_UDP_LISTEN_PORT)!)
      // TODO: 这条会让测试失败testConnectionNameChangeWhenReady()
      parameters.requiredInterfaceType = .wifi
      parameters.allowLocalEndpointReuse = true
    }
    
    let connection = NWConnection(to: endpoint, using: parameters)
    self.connection = connection
    self.initiatedConnection = true

    startConnection()
  }
    
  // 创建收到连接请求时候的被动接入连接
  init(connection: ConnectionProtocol, delegate: YMLNWConnectionDelegate) {
    self.delegate = delegate
    self.endPoint = nil

    self.connection = connection
    self.initiatedConnection = false
    
    // TODO: - 传入的Connection类型如何判断？
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
//      print("\(connection) established")
      os_log("established", log: self.log)
      
      // 如果准备就绪就开始接收消息
      self.setReceive()
      
      // TODO: - 需要修改：如果是UDP则通知代理已经准备好，TCP需要在握手完成后才通知
      if let delegate = self.delegate {
        delegate.connectionReady(connection: self)
      }
          
    case .failed(let error):
      print(#line, #function, "\(connection) failed with \(error)")
              
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
        delegate.connectionError(connection: self, error: error)
      }
    case .cancelled:
      self.delegate?.connectionFailed(connection: self)
    default:
      break
    }
  }
    
    connection.pathUpdateHandler = {newPath in
      print(#line,#function, newPath.debugDescription)
    }
        
    // TODO: - 可以设置更灵活的queue
    connection.start(queue: DispatchQueue.global())
    
    if type == .tcp { setHeartbeat() } // 如果是TCP连接，设置心跳包
  }
    
  // MARK: - Send
    
  // 设置发送消息
  func send(content: Data) {

    switch type {
    case .udp, .broadcast:
      sendByMessage(content: content)
    case .tcp:
      sendByStream(content: content)
    }
  }
  
  private func sendByMessage(content: Data) {
    guard let connection = connection else { return }
    connection.send(content: content, contentContext: .defaultMessage, isComplete: true, completion: .contentProcessed { [weak self] error in
      guard let self = self else { return }
              
      if let error = error {
        self.delegate?.connectionError(connection: self, error: error)
      } else {
        print("Send \(content.count) bytes to: \(connection.endpoint.debugDescription) ")
      }
    })
  }
  
  private func sendByStream(content: Data) {
    guard let connection = connection else { return }
    connection.send(content: content, contentContext: .defaultMessage, isComplete: false, completion: .contentProcessed { [weak self] error in
      guard let self = self else { return }
              
      if let error = error {
        self.delegate?.connectionError(connection: self, error: error)
      } else {
        print("Send \(content.count) bytes to: \(connection.endpoint.debugDescription) ")
      }
    })
  }

  // MARK: - Receive
    
  func setReceive() {
    switch type {
    case .udp, .broadcast:
      receiveByMessage()
    case .tcp:
      receiveByStream()
    }
  }
    
  // 设置接收消息，转交给代理，并接受下一个消息 主要用于UDP？
  func receiveByMessage() {
    guard let connection = connection else { return }
        
    connection.receiveMessage { content, _, _, error in
            
      if let data = content, !data.isEmpty {
        print("\(connection.endpoint.debugDescription) receive \(data.count) bytes")
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
  // TCP数据的格式是：Header(Length_2Bytes+CMD_2Bytes)+Body,
  // 参考安卓平台方式一样，需要将此数据包（包括Header+Body）完整透传给上层App
  func receiveByStream() {
    guard let connection = connection else { return }
    let headerLength = 2 * MemoryLayout<UInt16>.size
    
    connection.receive(minimumIncompleteLength: headerLength, maximumLength: headerLength) { content, context, isComplete, error in
      var packetLen: UInt16 = 0 //包体的长度
      var packetCmd: [UInt8] = [] // 命令字
      var willDeliverData = Data() //需要向App提交的数据
      
      // 解码获取body长度值
      if let packetHeaderData = content, !packetHeaderData.isEmpty {
        packetLen = packetHeaderData.withUnsafeBytes { ptr in ptr.bindMemory(to: UInt16.self)[0].bigEndian }
        packetCmd.append(contentsOf:packetHeaderData[2...3]) //设置命令字
        willDeliverData.append(contentsOf: packetHeaderData) // 添加HeadData
      }
      
      if isComplete { self.cancel() }
      
      if let error = error {self.delegate?.connectionError(connection: self, error: error)}
      //如果没有出错，继续处理
      else if packetLen == 0
      // 处理纯header的情况
      {
        switch packetCmd  {
        case [0x40, 0x01]: //如果是心跳包，则打印完事
          print(#line, #function, "Received a heartBeat", willDeliverData.debugDescription)
        default: //不是心跳包则传递数据
          self.delegate?.receivedMessage(content: willDeliverData, connection: self)
        }
        self.receiveByStream() // 继续监听
      } else
      // body长度不为零，继续调用方法获得该长度的数据
      {
        self.connection?.receive(minimumIncompleteLength: Int(packetLen), maximumLength: Int(packetLen))
          { content, context, isComplete, error in
            
            if let bodyData = content, !bodyData.isEmpty {
              
              // 这一段打印信息可以考虑去掉
              let message = String(data: bodyData, encoding: .utf8)
              let logMessage = "TCP connection did receive, data: \(bodyData as NSData) string: \(message ?? "-")  ip: \(self.name) context:\(String(describing: context?.identifier))"
              print(#line, logMessage)
                        
              willDeliverData.append(contentsOf: bodyData)
              print(#line, willDeliverData as NSData)
              self.delegate?.receivedMessage(content: willDeliverData, connection: self)
            }

            if isComplete { self.cancel() }
                    
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
  
    
  // MARK: - Heartbeat
    
  func setHeartbeat() {
        
    heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { _ in
      self.sendHeartbeat()
    })
        
    heartbeatTimer?.fire()
  }
    
  private func sendHeartbeat() {
    guard connection?.state == .ready else { return }
        
    let heartBeat:Data = HeartBeat().encodedData//Data([UInt8](arrayLiteral: 0x00, 0x00, 0x10, 0x00))
    send(content: heartBeat)
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



