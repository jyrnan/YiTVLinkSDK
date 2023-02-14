import Foundation
import Network

@available(macOS 10.14, *)
class Server {
    let port: NWEndpoint.Port
    let listener: NWListener
    
    private var connectionsByID: [Int: ServerConnection] = [:]
    
    //设置回调方法
    var didReceivedCallback: (() -> Void)? = nil
    var echoData: Data? = nil
    var shouldRecieveData: Data? = nil
    
    init(port: UInt16) {
        self.port = NWEndpoint.Port(rawValue: port)!
        
        self.listener = try! NWListener(using: .tcp, on: self.port)
    }
    
    func start() throws {
        print("TCP Server starting...")
        self.listener.stateUpdateHandler = self.stateDidChange(to:)
        self.listener.newConnectionHandler = self.didAccept(nwConnection:)
        self.listener.start(queue: .main)
    }
    
    func stateDidChange(to newState: NWListener.State) {
        switch newState {
        case .ready:
            print("TCP Server ready. port:\(listener.port)")
        case .failed(let error):
            print("TCP Server failure, error: \(error.localizedDescription)")
            exit(EXIT_FAILURE)
        default:
            break
        }
    }
    
    private func didAccept(nwConnection: NWConnection) {
        let connection = ServerConnection(nwConnection: nwConnection)
        self.connectionsByID[connection.id] = connection
        connection.didStopCallback = { _ in
            self.connectionDidStop(connection)
        }
        
        connection.didReceivedCallback = self.didReceivedCallback
        connection.echoData = self.echoData
        connection.shouldRecieveData = self.shouldRecieveData
        
        connection.start()
        connection.send(data: makeRegisterMockPack())
//        connection.send(data: "Welcome you are connection: \(connection.id)".data(using: .utf8)!)
        print("TCP server did open connection \(connection.id)")
    }
    
    private func connectionDidStop(_ connection: ServerConnection) {
        self.connectionsByID.removeValue(forKey: connection.id)
        print("TCP server did close connection \(connection.id)")
    }
    
    private func stop() {
        self.listener.stateUpdateHandler = nil
        self.listener.newConnectionHandler = nil
        self.listener.cancel()
        for connection in self.connectionsByID.values {
            connection.didStopCallback = nil
            connection.stop()
        }
        self.connectionsByID.removeAll()
    }
    
    private func makeRegisterMockPack() -> Data {
        var sendPack = Data(capacity: 4)
        var length = UInt16(MemoryLayout<UInt32>.size + 2).bigEndian
        let packLengthData = Data(bytes: &length, count: MemoryLayout.size(ofValue: length))
        
        var token = arc4random()
        let tokenData = Data(bytes: &token, count: MemoryLayout<UInt32>.size)
        
        sendPack.append(packLengthData)
        sendPack.append(contentsOf: [0x00, 0x02])
        sendPack.append(tokenData)
        
        return sendPack
    }
}
