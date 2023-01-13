//
//  Client+Request.swift
//  Vehicle tracking
//
//  Created by Jalilov, Artyom on 28.12.22.
//

import Foundation
import Moya

extension Client {
  public func allUsers<Target: TargetType>(_ target: Target)
  -> Request<UsersListResult, APIError, Target> {
    return Request(target: target, handler: handle)
  }
  
  public func userCars<Target: TargetType>(_ target: Target)
  -> Request<UserCarsResult, APIError, Target> {
    return Request(target: target, handler: handle)
  }
}
