import Foundation

public protocol BotPlayer {
    init()
    var loopsPerTick: Int { get }
    var saveReplay: Bool { get }
    
    func runTick(gamestate: GamestateHelper)
    func debug() -> [DebugCommand]
    func saveReplay(_ data: Data)
}

public struct PlaceBuilding {
    public let unit: UnitTag
    public let ability: Ability
    public var ignoreResourceRequirements: Bool
    public let position: Position.World2D
    public let onSuccess: (GamestateHelper) -> ()
}

extension BotPlayer {
    public var loopsPerTick: Int { 1 }
    public var saveReplay: Bool { true }
}

public struct Grid {
    let sc2: SC2APIProtocol_ImageData
    
    init(sc2: SC2APIProtocol_ImageData) {
        self.sc2 = sc2
        
        if sc2.bitsPerPixel != 1 {
            fatalError("sc2.startRaw.placementGrid.bitsPerPixel != 1")
        }
    }
    
    public subscript(x: Int, y: Int) -> Bool {
        let bit = (x + (y * Int(sc2.size.x)))
        let byte = sc2.data[(bit / 8)] >> (7 - (bit % 8))
        return (byte & 0b00000001) != 0
    }
}

public struct GameInfo {
    let sc2: SC2APIProtocol_ResponseGameInfo
    
    public var startLocations: [Position.World2D] {
        sc2.startRaw.startLocations.map(Position.World2D.init)
    }
    
    public var placementGrid: Grid {
        Grid(sc2: sc2.startRaw.placementGrid)
    }
}

public final class GamestateHelper {
    public internal(set) var observation: Observation
    internal var actions = [Action]()
    internal var placedBuildings = [PlaceBuilding]()
    public let gameInfo: GameInfo
    private var cache = [String: Any]()
    public private(set) var willQuit = false
    
    init(observation: Observation, gameInfo: GameInfo) {
        self.observation = observation
        self.gameInfo = gameInfo
    }
    
    func clearCache() {
        cache.removeAll(keepingCapacity: true)
    }
    
    public func cached<T>(byKey key: String, run: () -> T) -> T {
        if let value = cache[key] {
            return value as! T
        }
        
        let value = run()
        cache[key] = value
        return value
    }
    
    public var economy: ObservedPlayer {
        self.observation.player
    }
    
    public func quit() {
        willQuit = true
    }
    
    public var units: [AnyUnit] {
        observation.observation.rawData.units.map { unit in
            AnyUnit(sc2: unit, helper: self)
        }
    }
    
    public func canPlace<B: Building>(_ building: B.Type, at location: Position.World2D) -> Bool {
        let creepGrid = observation.creepGrid
        let placementGrid = gameInfo.placementGrid
        
        switch B.creepPlacement {
        case .requires(let creepRequirement):
            for x in B.positioning {
                for y in B.positioning {
                    if creepGrid[x, y] != creepRequirement {
                        return false
                    }
                    
                    if !placementGrid[x, y] {
                        return false
                    }
                }
            }
        case .optional:
            for x in B.positioning {
                for y in B.positioning {
                    if !placementGrid[x, y] {
                        return false
                    }
                }
            }
        }
        
        return true
    }
    
    public func canAfford<U: Entity>(_ unit: U.Type) -> Bool {
        self.canAfford(U.cost)
    }
    
    public func canTrain<U: Entity>(_ unit: U.Type) -> Bool {
        unit.supply <= economy.freeSupply && canAfford(U.cost)
    }
    
    public func afford<U: Entity>(_ unit: U.Type, run: () -> ()) -> Bool {
        if !self.canAfford(U.cost) {
            return false
        }
        
        run()
        
        return true
    }
    
    public func train<U: Entity>(_ unit: U.Type, run: () -> ()) -> Bool {
        if !canTrain(unit) {
            return false
        }
        
        run()
        
        return true
    }
    
    public func canAfford(_ cost: Cost) -> Bool {
        if cost.minerals > observation.player.minerals {
            return false
        }
        
        if cost.vespene > observation.player.vespene {
            return false
        }
        
        return true
    }
}

public struct Cost {
    public var minerals: Int
    public var vespene: Int
    
    public static func minerals(_ minerals: Int) -> Cost {
        Cost(minerals: minerals, vespene: 0)
    }
    
    public static let none = Cost(minerals: 0, vespene: 0)
    
    public static func vespene(_ vespene: Int) -> Cost {
        Cost(minerals: 0, vespene: vespene)
    }
    
    public func canAfford(_ cost: Cost) -> Bool {
        cost.minerals <= minerals && cost.vespene <= vespene
    }
    
    public func canAfford<E: Entity>(_ entity: E.Type) -> Bool {
        canAfford(E.cost)
    }
    
    @discardableResult
    public mutating func afford(_ cost: Cost, run: () -> ()) -> Bool {
        if canAfford(cost) {
            minerals -= cost.minerals
            vespene -= cost.vespene
            run()
            return true
        }
        
        return false
    }
    
    @discardableResult
    public mutating func afford<E: Entity>(_ entity: E.Type, run: () -> ()) -> Bool {
        afford(E.cost, run: run)
    }
    
    public init(
        minerals: Int,
        vespene: Int
    ) {
        self.minerals = minerals
        self.vespene = vespene
    }
}

public func -(lhs: Cost, rhs: Cost) -> Cost {
    Cost(minerals: lhs.minerals - rhs.minerals, vespene: lhs.vespene - rhs.vespene)
}

public func -=(lhs: inout Cost, rhs: Cost) {
    lhs = lhs - rhs
}

public func +(lhs: Cost, rhs: Cost) -> Cost {
    Cost(minerals: lhs.minerals + rhs.minerals, vespene: lhs.vespene + rhs.vespene)
}

public func /(lhs: Cost, rhs: Cost) -> Int {
    func remainderMinerals() -> Int { lhs.minerals % rhs.minerals }
    func remainderVespene() -> Int { lhs.vespene % rhs.vespene }
    
    if rhs.minerals == 0 && rhs.vespene != 0 {
        return (lhs.vespene - remainderVespene()) / rhs.vespene
    } else if rhs.vespene == 0 && lhs.minerals != 0 {
        return (lhs.minerals - remainderMinerals()) / rhs.minerals
    } else if rhs.minerals != 0 && rhs.vespene != 0 {
        let minerals = (lhs.minerals - remainderMinerals()) / rhs.minerals
        let vespene = (lhs.vespene - remainderVespene()) / rhs.vespene
        
        return min(minerals, vespene)
    } else {
        assertionFailure("No resources being spent")
        return .max
    }
}

public func +=(lhs: inout Cost, rhs: Cost) {
    lhs = lhs + rhs
}

public struct Position {
    public struct World {
        var sc2: SC2APIProtocol_Point
        
        init(sc2: SC2APIProtocol_Point) {
            self.sc2 = sc2
        }
        
        init(x: Float, y: Float, z: Float) {
            var sc2 = SC2APIProtocol_Point()
            sc2.x = x
            sc2.y = y
            sc2.z = z
            self.sc2 = sc2
        }
        
        public var x: Float {
            get { sc2.x }
            set { sc2.x = newValue }
        }
        
        public var y: Float {
            get { sc2.y }
            set { sc2.y = newValue }
        }
        
        public var z: Float {
            get { sc2.z }
            set { sc2.z = newValue }
        }
        
        public var as2D: World2D {
            World2D(x: x, y: y)
        }
    }
    
    public struct World2D {
        var sc2: SC2APIProtocol_Point2D
        
        init(sc2: SC2APIProtocol_Point2D) {
            self.sc2 = sc2
        }
        
        init(x: Float, y: Float) {
            var sc2 = SC2APIProtocol_Point2D()
            sc2.x = x
            sc2.y = y
            self.sc2 = sc2
        }
        
        @inlinable
        public func distanceXorY(to coordinate: Self) -> Float {
            max(
                distance(inSpace: \.x, to: coordinate),
                distance(inSpace: \.y, to: coordinate)
            )
        }
        
        @inlinable
        public func distanceXY(to coordinate: Self) -> Float {
            let differenceX = distance(inSpace: \.x, to: coordinate)
            let differenceY = distance(inSpace: \.y, to: coordinate)
            let squaredX = differenceX * differenceX
            let squaredY = differenceY * differenceY
            return (squaredX + squaredY).squareRoot()
        }
        
        @inlinable
        public func distance(inSpace space: KeyPath<Self, Float>, to coordinate: Self) -> Float {
            abs(coordinate[keyPath: space] - self[keyPath: space])
        }
        
        @inlinable
        public func difference(inSpace space: KeyPath<Self, Float>, to coordinate: Self) -> Float {
            coordinate[keyPath: space] - self[keyPath: space]
        }
        
        public var x: Float {
            get { sc2.x }
            set { sc2.x = newValue }
        }
        
        public var y: Float {
            get { sc2.y }
            set { sc2.y = newValue }
        }
    }
    
    public struct Minimap {
        let sc2: SC2APIProtocol_PointI
    }
}

public struct WorldBounds {
    public var position: Position.World
    public var size: Size
}

public struct Size {
    let width: Float
    let height: Float
}
