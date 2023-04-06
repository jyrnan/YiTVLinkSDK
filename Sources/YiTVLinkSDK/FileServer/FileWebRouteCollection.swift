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
    return req.fileio.streamFile(at: fileURL.path)
  }
}

