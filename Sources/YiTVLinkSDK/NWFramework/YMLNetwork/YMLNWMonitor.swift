//
//  File.swift
//
//
//  Created by jyrnan on 2023/4/8.
//

import Foundation
import Network
import NetworkExtension

protocol YMLNWMonitorDelegate: AnyObject {
  func wifiStatusDidChanged(status: Network.NWPath.Status)
}

class YMLNWMonitor {
//  static let shared = YMLNWMonitor()
  
  private let queue = DispatchQueue(label: "YMLNWConnectivityMonitor")
  private let monitor: NWPathMonitor
  
  weak var delegate: YMLNWMonitorDelegate?
  
  init(delegate: YMLNWMonitorDelegate) {
    monitor = NWPathMonitor(requiredInterfaceType: .wifi)
    startMonitoring()
    self.delegate = delegate
  }
  
  func startMonitoring() {
    monitor.pathUpdateHandler = { [weak self] path in
      guard let self else {return}
//      path.status == .satisfied
//      print(path.availableInterfaces)
      print(#line, #function, path.debugDescription)
      
        delegate?.wifiStatusDidChanged(status: path.status)
      
//          NEHotspotNetwork.fetchCurrent { info in
//            print(info?.ssid)
//          }
    }
    monitor.start(queue: queue)
  }
  
  func stopMonitoring() {
    monitor.cancel()
  }
}
