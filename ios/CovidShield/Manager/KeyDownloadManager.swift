//
//  ExposureManager.swift
//  CovidShield
//
//  Created by Avinash P on 9/28/20.
//

import Foundation
import Promises
import Alamofire

typealias JSONObject = [String: Any]

public enum GenericError: Error {

  case unknown
  case badRequest
  case cancelled
  case notFound
  case notImplemented
  case unauthorized

}

struct StructuredError: Error, Decodable {

  let title: String?
  let message: String

  init(title: String? = nil, message: String) {
    self.title = title
    self.message = message
  }
}

enum Key {
  static let error = "error"
  static let errorMessage = "error_description"
}


@objc final class KeyDownloadManager: NSObject {
  @objc static let shared = KeyDownloadManager()
  
  @objc var lastURLPath: String = ""
  
  let sessionManager: SessionManager = {
    let configuration = URLSessionConfiguration.default
    let headers = SessionManager.defaultHTTPHeaders
    configuration.httpAdditionalHeaders = headers
    configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    return SessionManager(configuration: configuration)
  }()
  
  func validate(request: URLRequest?, response: HTTPURLResponse, data: Data?) -> Request.ValidationResult {
    if (200...399).contains(response.statusCode) {
      return .success
    }

    // Attempt to deserialize structured error, if it exists
    if let data = data, let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? JSONObject, let _ = json[Key.error] as? JSONObject {
      return .failure(GenericError.unknown)
    }

    // Fallback on a simple status code error
    
    return .failure(GenericError.unknown)
  }
  
  func fetchKeyURLList() -> Promise<[String]> {
    return Promise<[String]> { fullfill, reject in
      let requestURL = URL(string: "https://encdn.integration.exposurenotification.health/v1pr/index.txt")
      self.sessionManager.request(requestURL!, method: .get, parameters: nil, encoding: URLEncoding.default).validate(self.validate).responseData { response in
        switch (response.result) {
        case .success(let data):
          let urlPaths = String(decoding: data, as: UTF8.self).split(separator: "\n").map { String($0) }
          let remoteURLs: [String] = self.urlPathsToProcess(urlPaths)
          self.lastURLPath = remoteURLs.last ?? ""
          fullfill(remoteURLs)
        case .failure(let error):
          reject(error)
        }
      }
    }
  }
  
  func downloadKeyArchives(targetUrls: [String]) -> Promise<[DownloadedPackage]> {
    return Promise { fullfill, reject in
      var downloadedPackages = [DownloadedPackage]()
      let dispatchGroup = DispatchGroup()
      for remoteURL in targetUrls {
        dispatchGroup.enter()
        let baseURL = URL(string: "https://encdn.integration.exposurenotification.health/")
        let finalURL = baseURL!.appendingPathComponent(remoteURL)

        self.sessionManager.request(finalURL).responseData { response in
          guard let data = response.result.value else {
            reject(GenericError.unknown)
            return
          }
          
          if let file = DownloadedPackage.create(from: data) {
            downloadedPackages.append(file)
          } else {
            reject(GenericError.unknown)
          }
          dispatchGroup.leave()
        }
      }
      
      dispatchGroup.notify(queue: .main) {
        fullfill(downloadedPackages)
      }
    }
  }
  
  func unpackKeyArchives(packages: [DownloadedPackage]) -> Promise<[URL]> {
    return Promise<[URL]>(on: .global()) { fullfill, reject in
      do {
        try packages.unpack({ (urls) in
          fullfill(urls)
        })
      } catch(let error) {
        reject(error)
      }
    }
  }

  
  @objc func downloadKeys(completion: @escaping ([String]?, Error?)->()) {
    Promise<[String]>(on: .global()) { () -> [String] in
      let fetchURLList = try await(self.fetchKeyURLList())
      let downloadedKeyArchives = try await(self.downloadKeyArchives(targetUrls: fetchURLList))
      let unpackKeyArchiveURL = try await(self.unpackKeyArchives(packages: downloadedKeyArchives))
      return unpackKeyArchiveURL.map { return $0.absoluteURL.path }
    }.then { result in
      completion(result, nil)
    }.catch { error in
      completion(nil, error)
    }
  }
}

extension KeyDownloadManager {
  func startIndex(for urlPaths: [String]) -> Int {
    let path = LocalStore.shared.latestDetectedURL
    if let lastIdx = urlPaths.firstIndex(of: path) {
      return min(lastIdx + 1, urlPaths.count)
    }
    return 0
  }

  func urlPathsToProcess(_ urlPaths: [String]) -> [String] {
    let startIdx = startIndex(for: urlPaths)
    let endIdx = min(startIdx + 15, urlPaths.count)
    return Array(urlPaths[startIdx..<endIdx])
  }
}

extension Array where Element == DownloadedPackage {

  func unpack(_ completion: @escaping (([URL]) -> Void)) throws {
    guard count > 0 else {
      completion([])
      return
    }
    var uncompressedFileUrls = [URL]()
    do {
      for idx in (0..<count) {
        let keyPackage = self[idx]
        let filename = UUID().uuidString
        
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        
        
        uncompressedFileUrls.append(try keyPackage.writeKeysEntry(toDirectory: documentDirectory!, filename: filename))
        uncompressedFileUrls.append(try keyPackage.writeSignatureEntry(toDirectory: documentDirectory!, filename: filename))
        if idx == count - 1 {
          completion(uncompressedFileUrls)
        }
      }
    } catch {
      uncompressedFileUrls.cleanup()
      throw GenericError.unknown
    }
  }
  
}

extension Array where Element == URL {

  func cleanup() {
    forEach { try? FileManager.default.removeItem(at: $0) }
  }

}
