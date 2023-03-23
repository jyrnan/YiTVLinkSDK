//
//  UDPServerConnection.swift
//  
//
//  Created by jyrnan on 2022/12/8.
//

import Foundation
import Network

@available(macOS 10.14, *)
class UDPServerConnection {
    
    private static var nextID: Int = 0
    let  connection: NWConnection
    let id: Int
    
    init(nwConnection: NWConnection) {
        connection = nwConnection
        id = UDPServerConnection.nextID
        UDPServerConnection.nextID += 1
    }
    
    var didStopCallback: ((Error?) -> Void)? = nil
    
    var didReceivedCallback: (() -> Void)? = nil
    var echoData: Data? = nil
    var shouldRecieveData: Data? = nil
    
    func start() {
        print("connection \(id) will start")
        connection.stateUpdateHandler = self.stateDidChange(to:)
        setupReceive()
        connection.start(queue: .main)
    }
    
    private func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .waiting(let error):
            connectionDidFail(error: error)
        case .ready:
            print("connection \(id) ready")
        case .failed(let error):
            connectionDidFail(error: error)
        default:
            break
        }
    }

    private func getHost() ->  NWEndpoint.Host? {
        switch connection.endpoint {
        case .hostPort(let host , _):
            return host
        default:
            return nil
        }
    }
    
    private func setupReceive() {
        connection.receiveMessage { (data, context, isComplete, error) in
            //这里按照另外一种处理收到信息的方式来调整了
            if let error = error {
                self.connectionDidFail(error: error)
            }
            guard isComplete, let data = data, !data.isEmpty else {
                self.connectionDidEnd()
                return
            }
            let message = String(data: data, encoding: .utf8)
            print("connection did receive, data: \(data as NSData) string: \(message ?? "-" )")
            
            if let data = self.echoData { self.send(data: data) } //echo回数据
            if let shouldRecieveData = self.shouldRecieveData {
                if data == shouldRecieveData { self.didReceivedCallback?() } //如果有设置判定数据，则必须收到和数据和判定数据一致才能执行可能的回调方法
            } else {
                self.didReceivedCallback?() //如果没有设置判定数据，则直接执行可能的回调方法
            }
            
            self.setupReceive() //继续监听
        }
    }

    
    func send(data: Data) {
        self.connection.send(content: data, completion: .contentProcessed( { error in
            if let error = error {
                self.connectionDidFail(error: error)
                return
            }
            print("connection \(self.id) did send, data: \(data as NSData)")
        }))
    }
    
    func stop() {
        print("connection \(id) will stop")
    }
    
    
    
    private func connectionDidFail(error: Error) {
        print("connection \(id) did fail, error: \(error)")
        stop(error: error)
    }
    
    private func connectionDidEnd() {
        print("connection \(id) did end")
        stop(error: nil)
    }
    
    private func stop(error: Error?) {
        connection.stateUpdateHandler = nil
        connection.cancel()
        if let didStopCallback = didStopCallback {
            self.didStopCallback = nil
            didStopCallback(error) //这个error参数在最终调用时候会无视
        }
    }
}
