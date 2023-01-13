//
//  UnauthorizedAPI.swift
//  Vehicle tracking
//
//  Created by Jalilov, Artyom on 28.12.22.
//

import Foundation
import Moya

public enum UnauthorizedAPI {
  case usersList
  case userCars(String)
}

extension UnauthorizedAPI: TargetType {
  public var baseURL: URL { URL(string: Client.url)! }
  
  public var path: String {
    switch self {
      case .usersList: return "api/"
      case .userCars(let id): return "api/"
    }
  }
  
  public var method: Moya.Method {
    switch self {
      case .usersList,
          .userCars:
        return .get
      default: return .get
    }
  }
  
  var parameterEncoding: ParameterEncoding {
    switch self {
      default:
        return URLEncoding.queryString
    }
  }
  
  var parameters : [String : Any]? {
    switch self {
      case .usersList:
        let params = [
          "op": "list"
        ] as [String: Any]
        return params
      case .userCars(let id):
        let params = [
          "op": "getlocations",
          "userid": id
        ] as [String: Any]
        return params
      default:
        return nil
    }
  }
  
  private func patchParam() -> Task {
    return .requestParameters(
      parameters: parameters!,
      encoding: URLEncoding.default
    )
  }
  
  public var task: Moya.Task {
    switch self {
      case .usersList: return patchParam()
      case .userCars: return patchParam()
      default: return .requestPlain
    }
  }
  
  public var headers: [String : String]? {
    switch self {
      default: return ["Content-type": "application/json"]
    }
  }
}
