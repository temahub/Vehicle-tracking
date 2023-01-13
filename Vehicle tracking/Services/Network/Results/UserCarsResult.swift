//
//  UserCarsResult.swift
//  Vehicle tracking
//
//  Created by Jalilov, Artyom on 11.01.23.
//

import Foundation

public struct UserCarsResult: Codable {
  public let data: [Car]?
}

public struct Car: Codable {
  public let vehicleid: Int
  public let lat: Double
  public let lon: Double
}
