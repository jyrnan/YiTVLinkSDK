import Foundation
import Network

@available(macOS 10.14, *)
class ServerConnection {
    //The TCP maximum package size is 64K 65536
    let MTU = 65536
    
    private static var nextID: Int = 0
    let  connection: NWConnection
    let id: Int
    
    init(nwConnection: NWConnection) {
        connection = nwConnection
        id = ServerConnection.nextID
        ServerConnection.nextID += 1
    }
    
    var didStopCallback: ((Error?) -> Void)? = nil
    
    //设置回调方法
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
        connection.receive(minimumIncompleteLength: 1, maximumLength: MTU) { (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                let message = String(data: data, encoding: .utf8)
                print("connection \(self.id) did receive, data: \(data as NSData) string: \(message ?? "-") ip: \(self.getHost() ?? "")")
                
                if let echoData = self.echoData { self.send(data: echoData) } else {
                    self.send(data: data)
                  print(#line, data as NSData)
                } //echo回数据
                if let shouldRecieveData = self.shouldRecieveData {
                    if data == shouldRecieveData { self.didReceivedCallback?() } //如果有设置判定数据，则必须收到和数据和判定数据一致才能执行可能的回调方法
                } else {
                    self.didReceivedCallback?() //如果没有设置判定数据，则直接执行可能的回调方法
                }
 
            }
            if isComplete {
                self.connectionDidEnd()
            } else if let error = error {
                self.connectionDidFail(error: error)
            } else {
                self.setupReceive()
            }
        }
    }

    
    func send(data: Data) {
        self.connection.send(content: data, completion: .contentProcessed( { error in
            if let error = error {
                self.connectionDidFail(error: error)
                return
            }
          print(#line, "connection \(self.id) did send to , data: \(data as NSData)")
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
            didStopCallback(error)
        }
    }
}
