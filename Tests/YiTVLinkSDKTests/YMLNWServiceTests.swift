//
//  YMLNWServiceTests.swift
//  YiTVLinkSDKTests
//
//  Created by jyrnan on 2022/12/26.
//

import XCTest
@testable import YiTVLinkSDK

final class YMLNWServiceTests: XCTestCase {
    var sut: YMLNetwork!
    var mockServer: MockServerNW!
    
    let sentTestData: Data = "TestData".data(using: .utf8)!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        try super.setUpWithError()
        
        sut = YMLNetwork()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try super.tearDownWithError()
        
        if mockServer != nil {
            mockServer.tcpServer = nil
            mockServer.udpServer = nil
            mockServer = nil
        }
        sut = nil
    }
    
    fileprivate func createAndSetupMockServer(tcpPort: UInt16? = nil, udpPort: UInt16? = nil) {
        let tcpPort = tcpPort ?? randomValidPort()
        let udpPort = udpPort ?? randomValidPort()
        
        mockServer = MockServerNW(tcpPort: tcpPort, udpPort: udpPort)
        _ = mockServer.setupUdpServer()
        _ = mockServer.setupTcpServer()
    }
    
    fileprivate func randomValidPort() -> UInt16 {
        let minPort = UInt32(1024)
        let maxPort = UInt32(UINT16_MAX)
        let value = maxPort - minPort + 1
        return UInt16(minPort + arc4random_uniform(value))
    }

    /// 模拟增加一个发现的设备
    fileprivate func addMockAsDiscoveredDevice(device: DeviceInfo) {
        let isMockerServer = device.devName == "localMockServer"
        let tcpPort: UInt16 = isMockerServer ? mockServer.tcpPort : randomValidPort()
        let udpPort: UInt16 = isMockerServer ? mockServer.udpPort : randomValidPort()
       
        let mockDiscoveryInfo = DiscoveryInfo(device: DeviceInfo.localMockServer, TcpPort: tcpPort, UdpPort: udpPort)
        sut.service.discoveredDevice.append(mockDiscoveryInfo)
    }
    
    // MARK: - 测试方法

    func testInitSDK() {
        sut.initSDK(key: "TestClientName")
        guard let service = sut.service as? YMLNWService else { XCTFail(); return }
        XCTAssertEqual(service.serviceKey, "TestClientName")
    }
    
    /// 目前测试会失败，因为客户udpListener端监听端口和本地mockServer的端口一样
    func testSearchDeviceInfo() {
        let dataSentExpectation = XCTestExpectation(description: "发送设备查找请求")
        let dataReceiveExpectation = XCTestExpectation(description: "获得返回设备信息")
        
        let didDeliverDeciceInfo = { dataReceiveExpectation.fulfill() }
        let didReceiveUdpData = { dataSentExpectation.fulfill() }
        
        let mockListener = MockListener(shouldRecieveData: sentTestData)
        mockListener.onDeliverDeviceInfo = didDeliverDeciceInfo
        
        createAndSetupMockServer(udpPort: YMLNetwork.DEV_DISCOVERY_UDP_PORT)
        
        mockServer.udpServer?.didReceivedCallback = didReceiveUdpData
        mockServer.udpServer?.echoData = mockServer.echoFoundDeviceData()
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1){
            self.sut.searchDeviceInfo(searchListener: mockListener)}
                
        wait(for: [dataSentExpectation], timeout: 1)
        wait(for: [dataReceiveExpectation], timeout: 1)
    }
    
    func testCreateUdpChannel() {
        let expectation = XCTestExpectation(description: "测试UDP连接成功回调")
        
        let mockListener = MockListener(shouldRecieveMessage: "UDPCONNECTED")
        mockListener.onNotified = {expectation.fulfill()}
        
        createAndSetupMockServer()
        addMockAsDiscoveredDevice(device: .localMockServer)
        
        //因为创建UPD通道没有设置listener的步骤，所以需要手动设置
        sut.service.lisener = mockListener
        
        XCTAssertTrue(sut.createUdpChannel(info: .localMockServer))
//        XCTAssertEqual(sut.service.udpClient?.port, mockServer.udpPort)
//        XCTAssertTrue(sut.service.udpClient?.connection?.state == .ready)
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testSendGeneralCommandRC() {
        let expectation = XCTestExpectation(description: "测试发送通用RemoteControl命令")
        let didSendGeneralCommand = { expectation.fulfill() }
        
        createAndSetupMockServer()
        mockServer.udpServer?.didReceivedCallback = didSendGeneralCommand
        
//        let command = RemoteControl.sample
//        let message = Message.remoteControl(command)
//        mockServer.udpServer?.shouldRecieveData = try? JSONEncoder().encode(message)
        
        let command = RemoteControl.sample
        let message = MessageWrapper(value: command)
        mockServer.udpServer?.shouldRecieveData = try? JSONEncoder().encode(message)
        
        
        addMockAsDiscoveredDevice(device: .localMockServer)
        guard sut.createUdpChannel(info: .localMockServer) else {
            XCTFail("不能建立本地连接，测试失败")
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.sut.sendGeneralCommand(command: command))}
        
        wait(for: [expectation], timeout: 1)
    }
    
    // MARK: - TCP
    
    func testCreateTcpChannel() {
        let expectation = XCTestExpectation(description: "测试TCP连接成功回调")
        
        let mockListener = MockListener(shouldRecieveMessage: "TCPCONNECTED")
        mockListener.onNotified = {expectation.fulfill()}
        
        createAndSetupMockServer()
        addMockAsDiscoveredDevice(device: .localMockServer)
        
        sut.receiveTcpData(TCPListener: mockListener)
        
        XCTAssertTrue(sut.createTcpChannel(info: .localMockServer))
//        XCTAssertEqual(sut.service.tcpClient?.connection?.endpoint, mockServer.tcpPort)
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testSendTcpData() {
        
        let expectation = XCTestExpectation(description: "测试TCP发送数据")
        let didReceiveTcpData = { expectation.fulfill() }
        
        createAndSetupMockServer()
        addMockAsDiscoveredDevice(device: .localMockServer)
        
        mockServer.tcpServer?.didReceivedCallback = didReceiveTcpData
        mockServer.tcpServer?.shouldRecieveData = sentTestData
        
        guard sut.createTcpChannel(info: .localMockServer) else {
            XCTFail("不能建立本地连接，测试失败")
            return
        }
        
        XCTAssertNotNil(sut.service.hasConnectedToDevice)
        
        // 由于创建的connection需要一定时间才能处于ready状态，所以这里需要延迟一点执行
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [sentTestData] in
            XCTAssertTrue(self.sut.service.tcpClient?.connection?.state == .ready)
            self.sut.sendTcpData(data: sentTestData)
        }
        
        wait(for: [expectation], timeout: 1)
        
        XCTAssert(sut.service.tcpClient?.connection?.state == .ready)
    }
    
    func testReceiveTcpData() {
        let testCount:Int = 200
        let expectation = XCTestExpectation(description: "测试接收TCP数据")
        expectation.expectedFulfillmentCount = testCount
        let didRecieveTcpData = { expectation.fulfill() }
        
        let mockListener = MockListener(shouldRecieveData: sentTestData)
        mockListener.onDeliver = didRecieveTcpData
        createAndSetupMockServer()
        addMockAsDiscoveredDevice(device: .localMockServer)
        
//        mockServer.tcpServer?.echoData = makeTcpSendPack(data: sentTestData)
        
        guard sut.createTcpChannel(info: .localMockServer) else {
            XCTFail("不能建立本地连接，测试失败")
            return
        }
        
        sut.receiveTcpData(TCPListener: mockListener)
        
        // 由于创建的connection需要一定时间才能处于ready状态，所以这里需要延迟一点执行
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [sentTestData] in
            XCTAssertTrue(self.sut.service.tcpClient?.connection?.state == .ready)
            Array(0..<testCount).forEach{_ in
                self.sut.sendTcpData(data: sentTestData)
            }

        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func makeTcpSendPack(data: Data) -> Data {
        var sendPack = Data(capacity: 4)
        var length = UInt16(data.count + 2).bigEndian
        let packLengthData = Data(bytes: &length, count: MemoryLayout.size(ofValue: length))
        
        sendPack.append(packLengthData)
        sendPack.append(contentsOf: [0x01, 0x00])
        sendPack.append(data)
        
        return sendPack
    }
}
