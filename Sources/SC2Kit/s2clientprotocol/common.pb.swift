// DO NOT EDIT.
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: s2clientprotocol/common.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that your are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

enum SC2APIProtocol_Race: SwiftProtobuf.Enum {
  typealias RawValue = Int
  case noRace // = 0
  case terran // = 1
  case zerg // = 2
  case protoss // = 3
  case random // = 4

  init() {
    self = .noRace
  }

  init?(rawValue: Int) {
    switch rawValue {
    case 0: self = .noRace
    case 1: self = .terran
    case 2: self = .zerg
    case 3: self = .protoss
    case 4: self = .random
    default: return nil
    }
  }

  var rawValue: Int {
    switch self {
    case .noRace: return 0
    case .terran: return 1
    case .zerg: return 2
    case .protoss: return 3
    case .random: return 4
    }
  }

}

#if swift(>=4.2)

extension SC2APIProtocol_Race: CaseIterable {
  // Support synthesized by the compiler.
}

#endif  // swift(>=4.2)

struct SC2APIProtocol_AvailableAbility {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var abilityID: Int32 {
    get {return _abilityID ?? 0}
    set {_abilityID = newValue}
  }
  /// Returns true if `abilityID` has been explicitly set.
  var hasAbilityID: Bool {return self._abilityID != nil}
  /// Clears the value of `abilityID`. Subsequent reads from it will return its default value.
  mutating func clearAbilityID() {self._abilityID = nil}

  var requiresPoint: Bool {
    get {return _requiresPoint ?? false}
    set {_requiresPoint = newValue}
  }
  /// Returns true if `requiresPoint` has been explicitly set.
  var hasRequiresPoint: Bool {return self._requiresPoint != nil}
  /// Clears the value of `requiresPoint`. Subsequent reads from it will return its default value.
  mutating func clearRequiresPoint() {self._requiresPoint = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _abilityID: Int32? = nil
  fileprivate var _requiresPoint: Bool? = nil
}

struct SC2APIProtocol_ImageData {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// Number of bits per pixel; 8 bits for a byte etc.
  var bitsPerPixel: Int32 {
    get {return _storage._bitsPerPixel ?? 0}
    set {_uniqueStorage()._bitsPerPixel = newValue}
  }
  /// Returns true if `bitsPerPixel` has been explicitly set.
  var hasBitsPerPixel: Bool {return _storage._bitsPerPixel != nil}
  /// Clears the value of `bitsPerPixel`. Subsequent reads from it will return its default value.
  mutating func clearBitsPerPixel() {_uniqueStorage()._bitsPerPixel = nil}

  /// Dimension in pixels.
  var size: SC2APIProtocol_Size2DI {
    get {return _storage._size ?? SC2APIProtocol_Size2DI()}
    set {_uniqueStorage()._size = newValue}
  }
  /// Returns true if `size` has been explicitly set.
  var hasSize: Bool {return _storage._size != nil}
  /// Clears the value of `size`. Subsequent reads from it will return its default value.
  mutating func clearSize() {_uniqueStorage()._size = nil}

  /// Binary data; the size of this buffer in bytes is width * height * bits_per_pixel / 8.
  var data: Data {
    get {return _storage._data ?? SwiftProtobuf.Internal.emptyData}
    set {_uniqueStorage()._data = newValue}
  }
  /// Returns true if `data` has been explicitly set.
  var hasData: Bool {return _storage._data != nil}
  /// Clears the value of `data`. Subsequent reads from it will return its default value.
  mutating func clearData() {_uniqueStorage()._data = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _storage = _StorageClass.defaultInstance
}

/// Point on the screen/minimap (e.g., 0..64).
/// Note: bottom left of the screen is 0, 0.
struct SC2APIProtocol_PointI {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var x: Int32 {
    get {return _x ?? 0}
    set {_x = newValue}
  }
  /// Returns true if `x` has been explicitly set.
  var hasX: Bool {return self._x != nil}
  /// Clears the value of `x`. Subsequent reads from it will return its default value.
  mutating func clearX() {self._x = nil}

  var y: Int32 {
    get {return _y ?? 0}
    set {_y = newValue}
  }
  /// Returns true if `y` has been explicitly set.
  var hasY: Bool {return self._y != nil}
  /// Clears the value of `y`. Subsequent reads from it will return its default value.
  mutating func clearY() {self._y = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _x: Int32? = nil
  fileprivate var _y: Int32? = nil
}

/// Screen space rectangular area.
struct SC2APIProtocol_RectangleI {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var p0: SC2APIProtocol_PointI {
    get {return _storage._p0 ?? SC2APIProtocol_PointI()}
    set {_uniqueStorage()._p0 = newValue}
  }
  /// Returns true if `p0` has been explicitly set.
  var hasP0: Bool {return _storage._p0 != nil}
  /// Clears the value of `p0`. Subsequent reads from it will return its default value.
  mutating func clearP0() {_uniqueStorage()._p0 = nil}

  var p1: SC2APIProtocol_PointI {
    get {return _storage._p1 ?? SC2APIProtocol_PointI()}
    set {_uniqueStorage()._p1 = newValue}
  }
  /// Returns true if `p1` has been explicitly set.
  var hasP1: Bool {return _storage._p1 != nil}
  /// Clears the value of `p1`. Subsequent reads from it will return its default value.
  mutating func clearP1() {_uniqueStorage()._p1 = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _storage = _StorageClass.defaultInstance
}

/// Point on the game board, 0..255.
/// Note: bottom left of the screen is 0, 0.
struct SC2APIProtocol_Point2D {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var x: Float {
    get {return _x ?? 0}
    set {_x = newValue}
  }
  /// Returns true if `x` has been explicitly set.
  var hasX: Bool {return self._x != nil}
  /// Clears the value of `x`. Subsequent reads from it will return its default value.
  mutating func clearX() {self._x = nil}

  var y: Float {
    get {return _y ?? 0}
    set {_y = newValue}
  }
  /// Returns true if `y` has been explicitly set.
  var hasY: Bool {return self._y != nil}
  /// Clears the value of `y`. Subsequent reads from it will return its default value.
  mutating func clearY() {self._y = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _x: Float? = nil
  fileprivate var _y: Float? = nil
}

/// Point on the game board, 0..255.
/// Note: bottom left of the screen is 0, 0.
struct SC2APIProtocol_Point {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var x: Float {
    get {return _x ?? 0}
    set {_x = newValue}
  }
  /// Returns true if `x` has been explicitly set.
  var hasX: Bool {return self._x != nil}
  /// Clears the value of `x`. Subsequent reads from it will return its default value.
  mutating func clearX() {self._x = nil}

  var y: Float {
    get {return _y ?? 0}
    set {_y = newValue}
  }
  /// Returns true if `y` has been explicitly set.
  var hasY: Bool {return self._y != nil}
  /// Clears the value of `y`. Subsequent reads from it will return its default value.
  mutating func clearY() {self._y = nil}

  var z: Float {
    get {return _z ?? 0}
    set {_z = newValue}
  }
  /// Returns true if `z` has been explicitly set.
  var hasZ: Bool {return self._z != nil}
  /// Clears the value of `z`. Subsequent reads from it will return its default value.
  mutating func clearZ() {self._z = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _x: Float? = nil
  fileprivate var _y: Float? = nil
  fileprivate var _z: Float? = nil
}

/// Screen dimensions.
struct SC2APIProtocol_Size2DI {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var x: Int32 {
    get {return _x ?? 0}
    set {_x = newValue}
  }
  /// Returns true if `x` has been explicitly set.
  var hasX: Bool {return self._x != nil}
  /// Clears the value of `x`. Subsequent reads from it will return its default value.
  mutating func clearX() {self._x = nil}

  var y: Int32 {
    get {return _y ?? 0}
    set {_y = newValue}
  }
  /// Returns true if `y` has been explicitly set.
  var hasY: Bool {return self._y != nil}
  /// Clears the value of `y`. Subsequent reads from it will return its default value.
  mutating func clearY() {self._y = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _x: Int32? = nil
  fileprivate var _y: Int32? = nil
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "SC2APIProtocol"

extension SC2APIProtocol_Race: SwiftProtobuf._ProtoNameProviding {
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "NoRace"),
    1: .same(proto: "Terran"),
    2: .same(proto: "Zerg"),
    3: .same(proto: "Protoss"),
    4: .same(proto: "Random"),
  ]
}

extension SC2APIProtocol_AvailableAbility: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".AvailableAbility"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "ability_id"),
    2: .standard(proto: "requires_point"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularInt32Field(value: &self._abilityID)
      case 2: try decoder.decodeSingularBoolField(value: &self._requiresPoint)
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if let v = self._abilityID {
      try visitor.visitSingularInt32Field(value: v, fieldNumber: 1)
    }
    if let v = self._requiresPoint {
      try visitor.visitSingularBoolField(value: v, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: SC2APIProtocol_AvailableAbility, rhs: SC2APIProtocol_AvailableAbility) -> Bool {
    if lhs._abilityID != rhs._abilityID {return false}
    if lhs._requiresPoint != rhs._requiresPoint {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension SC2APIProtocol_ImageData: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".ImageData"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "bits_per_pixel"),
    2: .same(proto: "size"),
    3: .same(proto: "data"),
  ]

  fileprivate class _StorageClass {
    var _bitsPerPixel: Int32? = nil
    var _size: SC2APIProtocol_Size2DI? = nil
    var _data: Data? = nil

    static let defaultInstance = _StorageClass()

    private init() {}

    init(copying source: _StorageClass) {
      _bitsPerPixel = source._bitsPerPixel
      _size = source._size
      _data = source._data
    }
  }

  fileprivate mutating func _uniqueStorage() -> _StorageClass {
    if !isKnownUniquelyReferenced(&_storage) {
      _storage = _StorageClass(copying: _storage)
    }
    return _storage
  }

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    _ = _uniqueStorage()
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      while let fieldNumber = try decoder.nextFieldNumber() {
        switch fieldNumber {
        case 1: try decoder.decodeSingularInt32Field(value: &_storage._bitsPerPixel)
        case 2: try decoder.decodeSingularMessageField(value: &_storage._size)
        case 3: try decoder.decodeSingularBytesField(value: &_storage._data)
        default: break
        }
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      if let v = _storage._bitsPerPixel {
        try visitor.visitSingularInt32Field(value: v, fieldNumber: 1)
      }
      if let v = _storage._size {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
      }
      if let v = _storage._data {
        try visitor.visitSingularBytesField(value: v, fieldNumber: 3)
      }
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: SC2APIProtocol_ImageData, rhs: SC2APIProtocol_ImageData) -> Bool {
    if lhs._storage !== rhs._storage {
      let storagesAreEqual: Bool = withExtendedLifetime((lhs._storage, rhs._storage)) { (_args: (_StorageClass, _StorageClass)) in
        let _storage = _args.0
        let rhs_storage = _args.1
        if _storage._bitsPerPixel != rhs_storage._bitsPerPixel {return false}
        if _storage._size != rhs_storage._size {return false}
        if _storage._data != rhs_storage._data {return false}
        return true
      }
      if !storagesAreEqual {return false}
    }
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension SC2APIProtocol_PointI: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".PointI"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "x"),
    2: .same(proto: "y"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularInt32Field(value: &self._x)
      case 2: try decoder.decodeSingularInt32Field(value: &self._y)
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if let v = self._x {
      try visitor.visitSingularInt32Field(value: v, fieldNumber: 1)
    }
    if let v = self._y {
      try visitor.visitSingularInt32Field(value: v, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: SC2APIProtocol_PointI, rhs: SC2APIProtocol_PointI) -> Bool {
    if lhs._x != rhs._x {return false}
    if lhs._y != rhs._y {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension SC2APIProtocol_RectangleI: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".RectangleI"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "p0"),
    2: .same(proto: "p1"),
  ]

  fileprivate class _StorageClass {
    var _p0: SC2APIProtocol_PointI? = nil
    var _p1: SC2APIProtocol_PointI? = nil

    static let defaultInstance = _StorageClass()

    private init() {}

    init(copying source: _StorageClass) {
      _p0 = source._p0
      _p1 = source._p1
    }
  }

  fileprivate mutating func _uniqueStorage() -> _StorageClass {
    if !isKnownUniquelyReferenced(&_storage) {
      _storage = _StorageClass(copying: _storage)
    }
    return _storage
  }

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    _ = _uniqueStorage()
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      while let fieldNumber = try decoder.nextFieldNumber() {
        switch fieldNumber {
        case 1: try decoder.decodeSingularMessageField(value: &_storage._p0)
        case 2: try decoder.decodeSingularMessageField(value: &_storage._p1)
        default: break
        }
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      if let v = _storage._p0 {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
      }
      if let v = _storage._p1 {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
      }
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: SC2APIProtocol_RectangleI, rhs: SC2APIProtocol_RectangleI) -> Bool {
    if lhs._storage !== rhs._storage {
      let storagesAreEqual: Bool = withExtendedLifetime((lhs._storage, rhs._storage)) { (_args: (_StorageClass, _StorageClass)) in
        let _storage = _args.0
        let rhs_storage = _args.1
        if _storage._p0 != rhs_storage._p0 {return false}
        if _storage._p1 != rhs_storage._p1 {return false}
        return true
      }
      if !storagesAreEqual {return false}
    }
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension SC2APIProtocol_Point2D: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".Point2D"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "x"),
    2: .same(proto: "y"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularFloatField(value: &self._x)
      case 2: try decoder.decodeSingularFloatField(value: &self._y)
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if let v = self._x {
      try visitor.visitSingularFloatField(value: v, fieldNumber: 1)
    }
    if let v = self._y {
      try visitor.visitSingularFloatField(value: v, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: SC2APIProtocol_Point2D, rhs: SC2APIProtocol_Point2D) -> Bool {
    if lhs._x != rhs._x {return false}
    if lhs._y != rhs._y {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension SC2APIProtocol_Point: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".Point"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "x"),
    2: .same(proto: "y"),
    3: .same(proto: "z"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularFloatField(value: &self._x)
      case 2: try decoder.decodeSingularFloatField(value: &self._y)
      case 3: try decoder.decodeSingularFloatField(value: &self._z)
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if let v = self._x {
      try visitor.visitSingularFloatField(value: v, fieldNumber: 1)
    }
    if let v = self._y {
      try visitor.visitSingularFloatField(value: v, fieldNumber: 2)
    }
    if let v = self._z {
      try visitor.visitSingularFloatField(value: v, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: SC2APIProtocol_Point, rhs: SC2APIProtocol_Point) -> Bool {
    if lhs._x != rhs._x {return false}
    if lhs._y != rhs._y {return false}
    if lhs._z != rhs._z {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension SC2APIProtocol_Size2DI: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".Size2DI"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "x"),
    2: .same(proto: "y"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularInt32Field(value: &self._x)
      case 2: try decoder.decodeSingularInt32Field(value: &self._y)
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if let v = self._x {
      try visitor.visitSingularInt32Field(value: v, fieldNumber: 1)
    }
    if let v = self._y {
      try visitor.visitSingularInt32Field(value: v, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: SC2APIProtocol_Size2DI, rhs: SC2APIProtocol_Size2DI) -> Bool {
    if lhs._x != rhs._x {return false}
    if lhs._y != rhs._y {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}