//
//  YMLNWListener.swift
//  DemoNetworkApp
//
//  Created by jyrnan on 2023/1/17.
//

import Foundation
import Network

protocol ListenerProtocol: AnyObject {
  var stateUpdateHandler: ((_ newState: NWListener.State) -> Void)? {get set}
  var newConnectionHandler: ((_ connection: NWConnection) -> Void)? {get set}
  var port: NWEndpoint.Port? { get }

  func start(queue: DispatchQueue)
  func cancel()
}

// 应为Listener需要管理部分Connection，并向上透传connection的调用，所以继承YMLNWConnectionDelegate
protocol YMLNWListenerDelegate: YMLNWConnectionDelegate {
    func ListenerReady()
    func ListenerFailed()
}

class YMLNWListener {

    // MARK: - Properties
    
    weak var delegate: YMLNWListenerDelegate?
    var listener: ListenerProtocol?
    let port: UInt16
    
    //设置监听连接类型
    var type: PeerType = .tcp
    
    var connectionsByID: [UUID: YMLNWConnection] = [:]
    
    // MARK: - Inits
    
    // 创建一个指定端口号的监听者用来接收连接，根据指定类型来创建非加密tcp或者udp，默认tcp
    init(on port: UInt16, delegate: YMLNWListenerDelegate, type: PeerType = .tcp) {
        self.port = port
        self.delegate = delegate
        self.type = type
        
        self.setupListener()
    }
    
    
    // MARK: - Setup listener
    
    // 创建一个指定端口号的监听者用来接收连接，根据指定类型来创建tcp或者udp，默认tcp
    private func setupListener() {
        let parameters: NWParameters
        if case .tcp = type {
            parameters = .tcp
        } else {
            parameters = .udp
          // 这里的端口复用可以取消，可能是和创建的顺序有关？
//          parameters.allowLocalEndpointReuse = true
        }
        
        guard let port = NWEndpoint.Port(rawValue: port) else {return}
        
        do {
            let listener = try NWListener(using: parameters, on: port)
            self.listener = listener
            
            self.startListening()
        } catch {
            print("创建服务监听失败")
            abort()
        }
    }
    
    
    // MARK: - Start and stop
    
    func startListening() {
        // 设置状态改变回调方法
        self.listener?.stateUpdateHandler = self.listenerStateChanged
        
        // 处理新进入的连接的回调方法
        self.listener?.newConnectionHandler = self.newConnectionHandler
        
        self.listener?.start(queue: DispatchQueue.global())
    }
    
    func stopListening() {
        if let listener = listener {
            listener.cancel()
        }
        listener = nil
        // 停止并移除所有监听保存的连接
        self.connectionsByID.values.forEach { $0.cancel() }
        self.connectionsByID.removeAll()
    }
    
    func listenerStateChanged(newState: NWListener.State) {
        switch newState {
        case .setup:
            break
        case .waiting(let error):
          print("Listener is waiting with \(error)")
        case .ready:
            print("Listener ready on \(String(describing: self.listener?.port))")
            self.delegate?.ListenerReady()
        case .failed(let error):
            print("Listener failed with \(error), stopping")
            self.delegate?.ListenerFailed()
            self.stopListening()
//            }
        case .cancelled:
            self.delegate?.ListenerFailed()
        default:
            break
        }
    }
    
    private func newConnectionHandler(newConnection: NWConnection) {
        // 接受传入的NWConnection，并用它创建PeerConnection保存在PeerListener中
        let peerConnection = YMLNWConnection(connection: newConnection, delegate: self)
        
        // 设置Peer的类型和当前监听Peer类型一致
        peerConnection.type = self.type
        
        // 保存connection到收到的connection池中
        self.connectionsByID[peerConnection.id] = peerConnection
    }

    // MARK: - Send
    
    func sendTo(id: UUID, content: Data) {
        self.connectionsByID[id]?.send(content: content)
    }
}

// 因为PeerListener需要管理部分传入的Connection所以需要把自身设置成这些connection的代理
extension YMLNWListener: YMLNWConnectionDelegate {
    func connectionReady(connection: YMLNWConnection) {
        self.delegate?.connectionReady(connection: connection)
    }
    
    func connectionFailed(connection: YMLNWConnection) {
        self.connectionsByID[connection.id] = nil
        self.delegate?.connectionFailed(connection: connection)
    }
    
    func receivedMessage(content: Data?, connection: YMLNWConnection) {
        self.delegate?.receivedMessage(content: content, connection: connection)
    }
    
    func connectionError(connection: YMLNWConnection, error: NWError) {
        self.delegate?.connectionError(connection: connection, error: error)
    }
}

extension NWListener: ListenerProtocol{ }
