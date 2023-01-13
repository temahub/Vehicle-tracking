//
//  UnauthorizedNetworkManager.swift
//  Vehicle tracking
//
//  Created by Jalilov, Artyom on 28.12.22.
//

import Foundation
import Moya
import Alamofire

public struct UnauthorizedNetworkManager {
  private let client: Client
  private let provider: Provider<UnauthorizedAPI>
  
  public init(
    plugins: [PluginType],
    client: Client = Client()
  ) {
    provider = Provider(plugins: plugins)
    self.client = client
  }
}

extension UnauthorizedNetworkManager {
  private func isNoInternet(_ apiError: Client.APIError) -> Bool {
    guard let err = apiError.asError as? AFError,
          let error = err.underlyingError as NSError?,
          error.code == URLError.Code.notConnectedToInternet.rawValue
            || error.code == URLError.Code.dataNotAllowed.rawValue
            || error.code == URLError.Code.networkConnectionLost.rawValue
            || !Reachability.isConnectedToNetwork()
    else {
      return false
    }
    return true
  }
  
  private func execute<Result: Decodable, ErrorType: Decodable>(
    _ id: UUID,
    request: Client.Request<Result, ErrorType, UnauthorizedAPI>,
    onComplete: @escaping (Client.Response<Result, ErrorType>) -> Void
  ) {
    provider.process(
      Provider.Request(
        id: id,
        target: request.target,
        handler: { data, response, error in
          let result = request.handler(data, response, error)
          onComplete(result)
        },
        onProgress: nil
      )
    )
  }
}

extension UnauthorizedNetworkManager {
  public func processUsersList(
    uuid: UUID,
    onSuccess: CommandWith<UsersListResult>,
    onFail: CommandWith<UserListError>
  ) {
    let request = client.allUsers(UnauthorizedAPI.usersList)
    execute(uuid, request: request) { response in
      print("")
      print(response)
      switch response {
        case .success(let result):
          onSuccess.perform(with: result)
        case .failed(let error):
          guard !self.isNoInternet(error) else {
            onFail.perform(with: .noInternet)
            return
          }
        default: onFail.perform(with: .unprocessable)
      }
    }
  }
  
  public func processUserCars(
    uuid: UUID,
    params: String,
    onSuccess: CommandWith<UserCarsResult>,
    onFail: CommandWith<UserListError>
  ) {
    let request = client.userCars(UnauthorizedAPI.userCars(params))
    execute(uuid, request: request) { response in
      print("")
      print(response)
      switch response {
        case .success(let result):
          onSuccess.perform(with: result)
        case .failed(let error):
          guard !self.isNoInternet(error) else {
            onFail.perform(with: .noInternet)
            return
          }
        default: onFail.perform(with: .unprocessable)
      }
    }
  }
  
  
}
