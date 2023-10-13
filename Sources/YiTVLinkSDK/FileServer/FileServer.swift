//
//  File.swift
//
//
//  Created by jyrnan on 2023/3/28.
//

import Foundation
import SwiftUI
import Vapor

public class FileServer {
    var app: Application?
    public let port: Int
  
    public var isServerRunning: Bool { app != nil}
    var sharingFileURLs: [String: URL] = [:]

    init(port: Int) {
        self.port = port
        
    }
    
    private func createApp() {
        
        let newApp = Application(.development)
        configure(newApp)
        self.app = newApp
    }

    private func configure(_ app: Application) {
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = port

        app.routes.defaultMaxBodySize = "50MB"
    }

    public func start() {
      guard !self.isServerRunning else {
        print(#line, #function, "File server is running already.")
        return
      }
        createApp()
        
        Task(priority: .background) {
            do {
                try app?.register(collection: FileWebRouteCollection(server: self))
                try app?.start()
                
      
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    public func stop() {
        guard let runningApp = app else {return}
        Task.detached(priority: .background) {[weak self] in
            runningApp.shutdown()
            self?.app = nil
            print(#line ,#function, "File server shutdown!")
        }
    }
}

// MARK: - 文件共享部分

extension FileServer {
    func prepareFileForShareNoCopy(pickedURL: URL) -> String? {
        /// 启动服务器
        start()
    
        let filename = pickedURL.lastPathComponent
        sharingFileURLs[filename] = pickedURL
        return makeShareUrl(filename: filename)
    }
  
    func makeShareUrl(filename: String) -> String? {
        guard let host = getWiFiAddress() else { return nil }
        return "http://\(host):\(port)/\(filename)"
    }
}
