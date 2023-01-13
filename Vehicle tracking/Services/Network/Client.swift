//
//  Client.swift
//  Vehicle tracking
//
//  Created by Jalilov, Artyom on 28.12.22.
//

import Foundation
import Moya

public protocol CodableError: Error, Codable {
  init(error: Error)
}

public extension Client {
  struct EmptyResult: Decodable {}
}

public struct Client {
  public init() {}
  
  private let decoder: JSONDecoder = {
    let res = JSONDecoder()
    res.keyDecodingStrategy = .convertFromSnakeCase
    return res
  }()
}

extension Client {
  public func handle<ResultType: Decodable, ErrorType: CodableError>(
    data: Data?,
    response: URLResponse?,
    error: Error?
  ) -> Response<ResultType, ErrorType> {
    if let error = error as NSError? {
      switch (error.domain, error.code) {
      default: return .failed(ErrorType(error: error))
      }
    }
    
    guard let response = response as? HTTPURLResponse else {
      preconditionFailure("Response must be here if error is nil")
    }
    
    if response.statusCode == 401 {
      return .unauthorized
    }
    
    if !(200...299 ~= response.statusCode) {
      if let unwrappedData = data {
         if let error = try? decoder.decode(ErrorType.self, from: unwrappedData) {
           return .failed(error)
         } else {
           print(String(data: unwrappedData, encoding: .utf8) ?? "Data is nil.")
           return .unprocessable
         }
      } else {
        return .unprocessable
      }
    }
    
    guard let unwrappedData = data else {
      preconditionFailure("Data have to be here")
    }
    
    do {
      if ResultType.self == EmptyResult.self,
         let result = EmptyResult() as? ResultType {
        return .success(result)
      }
      if let result = unwrappedData as? ResultType {
        return .success(result)
      }
      let result = try decoder.decode(ResultType.self, from: unwrappedData)
      return .success(result)
    } catch {
      print(error)
      print(String(data: unwrappedData, encoding: .utf8) ?? "Data is nil.")
      return .failed(ErrorType(error: error))
    }
  }
}

extension Client {
  public enum Response<ResultType: Decodable, ErrorType: CodableError> {
    case success(ResultType)
    case unauthorized
    case failed(ErrorType)
    case unprocessable
  }
  
  public struct Request<ResultType: Decodable, ErrorType: CodableError, Target: TargetType> {
    public let target: Target
    public let handler: (Data?, URLResponse?, Error?) -> Response<ResultType, ErrorType>
  }
  
  public struct APIError: CodableError {
    public let code: String
    public let message: String
    public var asError: Error? { original }
    private var original: Error?
    
    public init(error: Error) {
      self.init(code: "", message: error.localizedDescription)
      original = error
    }
    
    public init(code: String, message: String) {
      self.code = code
      self.message = message
    }
    
    enum CodingKeys: String, CodingKey {
      case code
      case message
    }
  }
}
