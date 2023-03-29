//
//  File.swift
//  
//
//  Created by jyrnan on 2023/3/28.
//

import Foundation
import Vapor
import Leaf
import SwiftUI

public class FileServer: ObservableObject {
  var app: Application
  public let port: Int
  var isServerRunning: Bool = false

  var rootURL: URL? {try? URL.serverRoot()}

  init(port: Int) {
    self.port = port
    app = Application(.development)
    configure(app)
   
  }

  private func configure(_ app: Application) {
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = port

    app.views.use(.leaf)
    app.leaf.cache.isEnabled = app.environment.isRelease
    app.leaf.configuration.rootDirectory = Bundle.main.bundlePath
    app.routes.defaultMaxBodySize = "50MB"
    
  }

    public func start() {
      guard !self.isServerRunning else {
        print("Server is running already.")
        return
      }
      
      Task(priority: .background) {
        do {
          try app.register(collection: FileWebRouteCollection())
          try app.start()
          isServerRunning = true
      
        } catch {
          print(error.localizedDescription)
        }
      }
    }
}

// MARK: - 文件共享部分

extension FileServer {
  func prepareFileForShare(pickedURL: URL) -> String? {
    guard let localUrl = copyDocumentsToLocalDirectory(pickedURL: pickedURL) else {return nil}
    
    start() // 启动服务器
    notifyFileChange() // 通知文件共享目录改变
    
    let filename = localUrl.lastPathComponent
    return makeShareUrl(filename: filename)
  }
  
  private func copyDocumentsToLocalDirectory(pickedURL: URL) -> URL? {
    guard let rootUrl = rootURL else {
              return nil
          }
          do {
              var destinationDocumentsURL: URL = rootUrl
              
              destinationDocumentsURL = destinationDocumentsURL
                  .appendingPathComponent(pickedURL.lastPathComponent)
              var isDir: ObjCBool = false
              if FileManager.default.fileExists(atPath: destinationDocumentsURL.path, isDirectory: &isDir) {
                  try FileManager.default.removeItem(at: destinationDocumentsURL)
              }
              guard pickedURL.startAccessingSecurityScopedResource() else {print("problem");return nil}
              defer {
                  pickedURL.stopAccessingSecurityScopedResource()
              }
              try FileManager.default.copyItem(at: pickedURL, to: destinationDocumentsURL)
              print(FileManager.default.fileExists(atPath: destinationDocumentsURL.path))
              return destinationDocumentsURL
          } catch  {
              print(error)
          }
          return nil
      }
  
  private func makeShareUrl(filename:String) -> String? {
    guard let host = getWiFiAddress() else {return nil}
    return "http://\(host):\(port)"
  }
  
  func notifyFileChange() {
    DispatchQueue.main.async {
      NotificationCenter.default.post(name: .serverFilesChanged, object: nil)
    }
  }
}
