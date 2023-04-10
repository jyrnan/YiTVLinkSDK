//
//  File.swift
//
//
//  Created by jyrnan on 2023/4/8.
//

import Foundation
import Network
import NetworkExtension

class YMLNWMonitor {
  static let shared = YMLNWMonitor()
  
  private let queue = DispatchQueue(label: "YMLNWConnectivityMonitor")
  private let monitor: NWPathMonitor
  
  private init() {
    monitor = NWPathMonitor(requiredInterfaceType: .wifi)
    startMonitoring()
  }
  
  func startMonitoring() {
    monitor.pathUpdateHandler = { [weak self] path in
      path.status == .satisfied
      print(path.availableInterfaces)
      print(#line, #function, path.debugDescription)

      
          NEHotspotNetwork.fetchCurrent { info in
            print(info?.ssid)
          }
    }
    monitor.start(queue: queue)
  }
  
  func stopMonitoring() {
    monitor.cancel()
  }
}
