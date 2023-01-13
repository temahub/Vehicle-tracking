//
//  Types.swift
//  Vehicle tracking
//
//  Created by Jalilov, Artyom on 29.12.22.
//

import Foundation

public typealias Command = CommandWith<Void>
public let EmptyCommand = Command(action: {})
