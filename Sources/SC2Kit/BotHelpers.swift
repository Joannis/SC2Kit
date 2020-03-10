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

public struct PlacementGrid {
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
    
    public var placementGrid: PlacementGrid {
        PlacementGrid(sc2: sc2.startRaw.placementGrid)
    }
}

public final class GamestateHelper {
    public internal(set) var observation: Observation
    internal var actions = [Action]()
    internal var placedBuildings = [PlaceBuilding]()
    public let gameInfo: GameInfo
    public private(set) var willQuit = false
    
    init(observation: Observation, gameInfo: GameInfo) {
        self.observation = observation
        self.gameInfo = gameInfo
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
    public let minerals: Int
    public let vespene: Int
    
    public static func minerals(_ minerals: Int) -> Cost {
        Cost(minerals: minerals, vespene: 0)
    }
    
    public static let none = Cost(minerals: 0, vespene: 0)
    
    public static func vespene(_ vespene: Int) -> Cost {
        Cost(minerals: 0, vespene: vespene)
    }
    
    public init(
        minerals: Int,
        vespene: Int
    ) {
        self.minerals = minerals
        self.vespene = vespene
    }
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
        
        public func distanceXorY(to coordinate: Self) -> Float {
            max(
                distance(inSpace: \.x, to: coordinate),
                distance(inSpace: \.y, to: coordinate)
            )
        }
        
        public func distanceXY(to coordinate: Self) -> Float {
            let differenceX = distance(inSpace: \.x, to: coordinate)
            let differenceY = distance(inSpace: \.y, to: coordinate)
            let squaredX = differenceX * differenceX
            let squaredY = differenceY * differenceY
            return (squaredX + squaredY).squareRoot()
        }
        
        public func distance(inSpace space: KeyPath<Self, Float>, to coordinate: Self) -> Float {
            abs(coordinate[keyPath: space] - self[keyPath: space])
        }
        
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
