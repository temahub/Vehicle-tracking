//
//  Command.swift
//  Vehicle tracking
//
//  Created by Jalilov, Artyom on 29.12.22.
//

import Foundation

public final class CommandWith<T> {
  private let action: (T) -> Void

  // Block of `context` defined variables. Allows Command to be debugged
  private let file: StaticString
  private let function: StaticString
  private let line: Int
  private let id: String

  init(id: String = "unnamed",
       file: StaticString = #file,
       function: StaticString = #function,
       line: Int = #line,
       action: @escaping (T) -> Void) {
    self.id = id
    self.action = action
    self.function = function
    self.file = file
    self.line = line
  }

  func perform(with value: T) {
    action(value)
  }

  /// Placeholder for do nothing command
  static var nop: CommandWith { return CommandWith(id: "nop") { _ in } }

  /// Support for Xcode quick look feature.
  @objc
  func debugQuickLookObject() -> AnyObject? {
    return """
            type: \(String(describing: type(of: self)))
            id: \(id)
            file: \(file)
            function: \(function)
            line: \(line)
            """ as NSString
  }
}

/// Also pure simplification
extension CommandWith where T == Void {
  func perform() {
    perform(with: ())
  }
}

/// Allows commands to be compared and stored in sets and dicts.
/// Uses `ObjectIdentifier` to distinguish between commands
extension CommandWith: Hashable {
  public static func == (left: CommandWith, right: CommandWith) -> Bool {
    return ObjectIdentifier(left) == ObjectIdentifier(right)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self).hashValue)
  }
}

extension CommandWith {
  /// Allows to pin some value to some command
  func bind(to value: T) -> Command {
    return Command { self.perform(with: value) }
  }
}

extension CommandWith {
  func map<U>(transform: @escaping (U) -> T) -> CommandWith<U> {
    return CommandWith<U> { value in self.perform(with: transform(value)) }
  }
}

extension CommandWith {
  // Allows to easily move commands between queues
  func dispatched(on queue: DispatchQueue) -> CommandWith {
    return CommandWith { value in
      queue.async {
        self.perform(with: value)
      }
    }
  }
}
