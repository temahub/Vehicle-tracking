//
//  Provider.swift
//  Vehicle tracking
//
//  Created by Jalilov, Artyom on 29.12.22.
//

import Foundation
import Moya
import Alamofire

public final class Provider<Target> where Target: TargetType {
  public struct Request<Target: TargetType> {
    public let id: UUID
    public let target: Target
    public let handler: (Data?, URLResponse?, Error?) -> Void
    public let onProgress: ((Double) -> Void)?
  }
  
  private let provider: MoyaProvider<Target>
  private var active = [UUID: Cancellable]()
  private var completed = Set<UUID>()
  
  public init(plugins: [PluginType]) {
#if BETA
    let manager = ServerTrustManager(
      allHostsMustBeEvaluated: false,
      evaluators: [
        "localhost": DisabledTrustEvaluator()
      ]
    )
    
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 90
    let session = Alamofire.Session(configuration: configuration, serverTrustManager: manager)
    provider = MoyaProvider(session: session, plugins: plugins)
#else
    provider = MoyaProvider(plugins: plugins)
#endif
  }
  
  public func process(_ request: Request<Target>) {
    guard !completed.contains(request.id), active[request.id] == nil else { return }
    let task = provider.request(
      request.target,
      progress: { request.onProgress?($0.progress) },
      completion: { self.complete(request: request, response: $0) }
    )
    active[request.id] = task
  }
  
  public func cancel(task uuid: UUID) {
    guard let task = active[uuid] else {
      return
    }
    
    task.cancel() // Stop task execution
  }
  
  private func complete(request: Request<Target>, response: Result<Moya.Response, MoyaError>) {
    defer {
      active[request.id] = nil
      completed.insert(request.id)
    }
    
    switch response {
    case .success(let res):
      request.handler(res.data, res.response, nil)
    case .failure(let error):
      request.handler(nil, error.response?.response, error.errorUserInfo[NSUnderlyingErrorKey] as? Error)
    }
  }
  
  deinit {
    active.values.forEach { $0.cancel() }
  }
}
