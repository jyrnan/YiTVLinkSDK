//
//  YMLNetworkAPITests.swift
//  YiTVLinkSDKTests
//
//  Created by jyrnan on 2022/12/26.
//

import XCTest
@testable import YiTVLinkSDK

final class YMLNetworkAPITests: XCTestCase {
    var sut: YMLNetwork!
    var mockServer: BaseMockServer!
    var mockListener: BaseMockListener!
    var sentTestData: Data = DeviceDiscoveryPacket().encodedData // "TestData".data(using: .utf8)!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        try super.setUpWithError()
    
        // TODO: 这里不能用单例，否则会导致多次测试失败
        sut = YMLNetwork.shared
        sut.reset()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try super.tearDownWithError()
        mockServer = nil
        sut = nil
    }
    
    fileprivate func setupMockServerAsTCPMockServer(port: UInt16? = nil) {
        let port = port ?? TestUtility.makeRandomValidPort()
        mockServer = BaseMockServer(port: port, peerType: .tcp)
    }
  
    fileprivate func setupMockServerAsUDPMockServer(port: UInt16? = nil) {
        let port = port ?? TestUtility.makeRandomValidPort()
        mockServer = BaseMockServer(port: port, peerType: .udp)
    }

    /// 模拟增加一个发现的设备
    fileprivate func addLocalMockServeAsDiscoveredDevice(tcpPort: UInt16? = nil, udpPort: UInt16? = nil) {
        let tcpPort = tcpPort ?? TestUtility.makeRandomValidPort()
        let udpPort = udpPort ?? TestUtility.makeRandomValidPort()
        let mockDiscoveryInfo = DiscoveryInfo(device: DeviceInfo.localMockServer, TcpPort: tcpPort, UdpPort: udpPort)
        sut.service.deviceManager.discoveredDevice.append(mockDiscoveryInfo)
    }
    
    // MARK: - 测试方法

    func testInitSDK() {
        sut.initSDK(key: "TestClientName")
        guard let service = sut.service as? YMLNWService else { XCTFail(); return }
        XCTAssertEqual(service.serviceKey, "TestClientName")
    }
    
    /// 这个方法测试发送设备信息和listener收到信息后能调用callback
    // TODO: 需要完善的是这里不能采用真正的本地网络服务
    /// 这样无法进行自动化多个测试，网络功能需要单独的测试OK后
    /// 其余的测试环节应该采用mock来代替真实的网络服务
    /// 测试环节过长就变成了集成测试
    func testSearchDeviceInfo() {
        let dataSentExpectation = XCTestExpectation(description: "发送设备查找请求")
        let DeliverDeviceInfoExpectation = XCTestExpectation(description: "获得返回设备信息")
        
        let didDeliverDeviceInfo = { DeliverDeviceInfoExpectation.fulfill() }
        // TODO: - 如何让listener收到设备信息的回调？
        let didDataSentUdpData = { dataSentExpectation.fulfill()
            self.sut.service.appListener?.deliver(devices: [DeviceInfo()])
        }
        
        mockListener = SearchDeviceMockListener(callback: didDeliverDeviceInfo)
        mockServer = SearchDeviceEchoMockServer(port: YMLNetwork.DEV_DISCOVERY_UDP_PORT, peerType: .udp)
        mockServer.callback = didDataSentUdpData
        // FIXME: -
        mockServer.echo = DeviceDiscoveryFeedbackPacket().encodedData
   
//    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        sut.searchDeviceInfo(searchListener: mockListener)
//    }
                
        wait(for: [dataSentExpectation], timeout: 1)
        wait(for: [DeliverDeviceInfoExpectation], timeout: 1)
    }
    
    /// 目前的测试方式暂时对于SDK9版本的区别是测试不出来
    func testSearchDeviceInfoSDK9() {
        let dataSentExpectation = XCTestExpectation(description: "发送设备查找请求")
        let DeliverDeviceInfoExpectation = XCTestExpectation(description: "获得返回设备信息")
          
        let didDeliverDeviceInfo = { DeliverDeviceInfoExpectation.fulfill() }
        // TODO: - 如何让listener收到设备信息的回调？
        let didDataSentUdpData = { dataSentExpectation.fulfill()
            self.sut.service.appListener?.deliver(devices: self.sut.service.deviceManager.discoveredDevice.map { DiscoveryInfo in
                DiscoveryInfo.device
            })
        }
          
        mockListener = SearchDeviceMockListener(callback: didDeliverDeviceInfo)
        mockServer = SearchDeviceEchoMockServer(port: YMLNetwork.DEV_DISCOVERY_UDP_PORT, peerType: .udp)
        mockServer.callback = didDataSentUdpData
        // FIXME: -
        mockServer.echo = DeviceDiscoveryFeedbackPacketSDK9().encodedData
     
//      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        sut.searchDeviceInfo(searchListener: mockListener)
//      }
                  
        wait(for: [dataSentExpectation], timeout: 1)
        wait(for: [DeliverDeviceInfoExpectation], timeout: 1)
    }
    
    func testCreateUdpChannel() {
        let expectation = XCTestExpectation(description: "测试UDP连接成功回调")
        
        let mockListener = NotifiedMessageMockListener()
        mockListener.callback = { expectation.fulfill() }
    
        // UDP不真正创建链接，所以无须启动本地服务器
        addLocalMockServeAsDiscoveredDevice()
        // 因为创建UPD通道没有设置listener的步骤，所以需要手动设置
        sut.service.appListener = mockListener
        
        XCTAssertTrue(sut.createUdpChannel(info: .localMockServer))
        wait(for: [expectation], timeout: 1)
    }
    
    func testSendGeneralCommandRC() {
        let expectation = XCTestExpectation(description: "测试发送通用RemoteControl命令")
        let didSendGeneralCommand = { expectation.fulfill() }
    
        let mockServer = ReceiveMockServer(port: TestUtility.makeRandomValidPort(), peerType: .udp)
        mockServer.callback = didSendGeneralCommand
//        addLocalMockServeAsDiscoveredDevice(udpPort: mockServer.port)
        let testDevice = DeviceInfo()
        testDevice.udpPort = mockServer.port
        
        // 因为创建UPD通道没有设置listener的步骤，所以需要手动设置
        sut.service.appListener = mockListener
    
        let command = RemoteControl.sample
        
        guard sut.createUdpChannel(info: testDevice) else {
            XCTFail("不能建立本地连接，测试失败")
            return
        }
    
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.sut.sendGeneralCommand(command: command))
        }
     
        wait(for: [expectation], timeout: 1)
    }
    
    // MARK: - TCP
    
    func testCreateTcpChannel() {
        let expectation = XCTestExpectation(description: "测试TCP连接成功回调")
    
        // 创建回调Listener
        let mockListener = NotifiedMessageMockListener()
        mockListener.callback = { expectation.fulfill() }
    
        // 创建TCP连接需要有服务器来建立真实的连接，和UDP不同
        let mockServer = BaseMockServer(port: TestUtility.makeRandomValidPort(), peerType: .tcp)
        addLocalMockServeAsDiscoveredDevice(tcpPort: mockServer.port)
    
        // 这个方法来设置回调的litener，TCP连接建立后会回调litener的notify方法
        sut.receiveTcpData(TCPListener: mockListener)
        
        XCTAssertTrue(sut.createTcpChannel(info: .localMockServer))
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testSendTcpData() {
        let expectation = XCTestExpectation(description: "测试TCP发送数据")
        let didReceiveTcpData = { expectation.fulfill() }
    
        // 创建TCP连接需要有服务器来建立真实的连接，和UDP不同
        mockServer = ReceiveMockServer(port: TestUtility.makeRandomValidPort(), peerType: .tcp)
        mockServer.callback = didReceiveTcpData
//    addLocalMockServeAsDiscoveredDevice(tcpPort:mockServer.port)
        let deviceInfo = DeviceInfo()
        deviceInfo.tcpPort = mockServer.port
        print(deviceInfo.localIp)
       
        guard sut.createTcpChannel(info: deviceInfo) else {
            XCTFail("不能建立本地连接，测试失败")
            return
        }
        
        XCTAssertNotNil(sut.service.deviceManager.hasConnectedToDevice)
        
        // 由于创建的connection需要一定时间才能处于ready状态，所以这里需要延迟一点执行
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [sentTestData] in
            XCTAssertTrue(self.sut.service.tcpClient?.connection?.state == .ready)
            self.sut.sendTcpData(data: sentTestData)
        }
        
        wait(for: [expectation], timeout: 1)
    }
  
    func testReceiveTcpData() {
        let testCount = 10
        let expectation = XCTestExpectation(description: "测试接收TCP数据")
        expectation.expectedFulfillmentCount = testCount
        let didReceiveTcpData = { expectation.fulfill() }
      
        // 建立数据接收回调listener
        mockListener = ReceiveDataMockListener()
        mockListener.callback = didReceiveTcpData
    
        // 建立echoServer
        mockServer = EchoMockServer(port: TestUtility.makeRandomValidPort(), peerType: .tcp)
//    addLocalMockServeAsDiscoveredDevice(tcpPort: mockServer.port)
        let testDevice = DeviceInfo()
        testDevice.tcpPort = mockServer.port
        
        // 设置回调listener
        sut.receiveTcpData(TCPListener: mockListener)
    
        guard sut.createTcpChannel(info: testDevice) else {
            XCTFail("不能建立本地连接，测试失败")
            return
        }
        
        // 由于创建的connection需要一定时间才能处于ready状态，所以这里需要延迟一点执行
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [sentTestData] in
            XCTAssertTrue(self.sut.service.tcpClient?.connection?.state == .ready)
            for _ in Array(0 ..< testCount) {
                self.sut.sendTcpData(data: sentTestData)
            }
        }
        
        wait(for: [expectation], timeout: 1)
    }
}
