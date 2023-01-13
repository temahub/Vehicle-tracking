//
//  UsersList.swift
//  Vehicle tracking
//
//  Created by Jalilov, Artyom on 27.12.22.
//

import Foundation

public struct UsersListResult: Codable {
  public let data: [UserResult?]
}

public struct UserResult: Codable {
//  public let userid: String
  public let userid: Int?
  public let owner: Owner?
  public let vehicles: [Vehicle?]?
}

public struct Owner: Codable {
  public let name: String?
  public let surname: String?
  public let foto: String? //URL
}

public struct Vehicle: Codable {
//  public let vehicleid: String
  public let vehicleid: Int?
  public let make: String?
  public let model: String?
  public let year: String?
  public let color: String?
  public let vin: String?
  public let foto: String? //URL
}
