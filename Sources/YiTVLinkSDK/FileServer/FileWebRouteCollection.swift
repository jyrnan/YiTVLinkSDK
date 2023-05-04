//
//  File.swift
//  
//
//  Created by jyrnan on 2023/3/28.
//

import Vapor

struct FileWebRouteCollection: RouteCollection {
  weak var server: FileServer?
  
  func boot(routes: RoutesBuilder) throws {
    routes.get(use: rootViewHandler)
    routes.get(":filename", use: downloadFileHandler)
  }

  func rootViewHandler(_ req: Request) async throws -> String {
    return "Welcome to YiTVLink"
  }

  func downloadFileHandler(_ req: Request) throws -> Response {
    guard let filename = req.parameters.get("filename") else {
      throw Abort(.badRequest)
    }
    guard let fileURL = server?.sharingFileURLs[filename] else {return Response(status: .notFound)}
    print(fileURL)
    let response = req.fileio.streamFile(at: fileURL.path)
    print(response.headers["Content-Length"])
    let length = response.headers["Content-Length"]
    response.headers.add(name: "Content-Length", value: length.first!)
    response.headers.add(name: "Content-Encoding", value: "identity")
    
    print(response.headers)
    return response
  }
}

