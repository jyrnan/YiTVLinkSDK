//
//  File.swift
//  
//
//  Created by jyrnan on 2023/3/28.
//

import Vapor

struct FileWebRouteCollection: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.get(use: filesViewHandler)
    routes.get(":filename", use: downloadFileHandler)
    routes.get("delete", ":filename", use: deleteFileHandler)
    routes.post(use: uploadFilePostHandler)
  }

  func filesViewHandler(_ req: Request) async throws -> String {
    let documentsDirectory = try URL.serverRoot()
    let fileUrls = try documentsDirectory.visibleContents()
    let filenames = fileUrls.map { $0.lastPathComponent }
    let context = FileContext(filenames: filenames)
//    return try await req.view.render("files", context)
    return filenames.joined(separator: "\n")
  }

  func uploadFilePostHandler(_ req: Request) throws -> Response {
    let fileData = try req.content.decode(FileUploadPostData.self)
    let writeURL = try URL.serverRoot().appendingPathComponent(fileData.file.filename)
    try Data(fileData.file.data.readableBytesView).write(to: writeURL)
    notifyFileChange()
    return req.redirect(to: "/")
  }

  func downloadFileHandler(_ req: Request) throws -> Response {
    guard let filename = req.parameters.get("filename") else {
      throw Abort(.badRequest)
    }
    let fileUrl = try URL.serverRoot().appendingPathComponent(filename)
    return req.fileio.streamFile(at: fileUrl.path)
  }

  func deleteFileHandler(_ req: Request) throws -> Response {
    guard let filename = req.parameters.get("filename") else {
      throw Abort(.badRequest)
    }
    let fileURL = try URL.serverRoot().appendingPathComponent(filename)
    try FileManager.default.removeItem(at: fileURL)
    notifyFileChange()
    return req.redirect(to: "/")
  }

  func notifyFileChange() {
    DispatchQueue.main.async {
      NotificationCenter.default.post(name: .serverFilesChanged, object: nil)
    }
  }
}

struct FileContext: Encodable {
  var filenames: [String]
}

struct FileUploadPostData: Content {
  var file: File
}
