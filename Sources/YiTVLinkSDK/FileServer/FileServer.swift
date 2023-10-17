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
  
    public var isServerRunning: Bool { app != nil }
    var sharingFileURLs: [String: URL] = [:]
    
    weak var appListener: YMLListener?

    init(port: Int) {
        self.port = port
    }
    
    private func createApp() {
        let newApp = Application(.development)
        configure(newApp)
        app = newApp
    }

    private func configure(_ app: Application) {
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = port

        app.routes.defaultMaxBodySize = "50MB"
    }

    public func start() {
        Task.detached { @FileServerActor in
            print(#line, String(cString: __dispatch_queue_get_label(nil)))

            guard !self.isServerRunning else {
                print(#line, #function, "File server is running already.")
                self.appListener?.notified(with: YMLNotify.FILE_SERVER_STARTED.rawValue)
                return
            }
            
            self.createApp()
            
            do {
                try self.app?.register(collection: FileWebRouteCollection(server: self))
                try self.app?.start()
//                print(#line, String(cString: __dispatch_queue_get_label(nil)))
                
                self.appListener?.notified(with: YMLNotify.FILE_SERVER_STARTED.rawValue)
      
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    public func stop() {
        Task.detached { @FileServerActor in
            guard let runningApp = self.app else {
                self.appListener?.notified(with: YMLNotify.FILE_SERVER_STOPPED.rawValue)
                return
            }
            
            runningApp.shutdown()
            self.app = nil
            print(#line, #function, "File server shutdown!")
            
            self.appListener?.notified(with: YMLNotify.FILE_SERVER_STOPPED.rawValue)
        }
    }
    
    func setupListener(appListener: YMLListener) {
        guard self.appListener == nil else { return }
        self.appListener = appListener
    }
}

// MARK: - 文件共享部分

extension FileServer {
    func prepareFileForShareNoCopy(pickedURL: URL) -> String? {
        /// 启动服务器
//        start()
        guard isServerRunning else { return nil }
    
        let filename = pickedURL.lastPathComponent
        sharingFileURLs[filename] = pickedURL
        return makeShareUrl(filename: filename)
    }
  
    func makeShareUrl(filename: String) -> String? {
        guard let host = getWiFiAddress() else { return nil }
        return "http://\(host):\(port)/\(filename)"
    }
}

@globalActor
actor FileServerActor {
    static var shared: FileServerActor = .init()
}
