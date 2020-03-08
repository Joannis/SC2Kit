public protocol BotPlayerHelpers: BotPlayer {
    func runTick(gamestate: inout GamestateHelper)
}

extension BotPlayerHelpers {
    public func onStep(observing observation: Observation) -> [Action] {
        var helper = GamestateHelper(observation: observation)
        
        runTick(gamestate: &helper)
        
        return helper.actions
    }
}

public final class GamestateHelper {
    public internal(set) var observation: Observation
    public internal(set) var actions = [Action]()
    
    init(observation: Observation) {
        self.observation = observation
    }
    
    public var economy: ObservedPlayer {
        self.observation.player
    }
    
    public var units: [AnyUnit] {
        observation.observation.rawData.units.map { unit in
            AnyUnit(sc2: unit, helper: self)
        }
    }
    
    public func canAfford<U: Unit>(_ unit: U.Type) -> Bool {
        self.canAfford(U.cost)
    }
    
    public func canTrain<U: Unit>(_ unit: U.Type) -> Bool {
        unit.supply < economy.freeSupply && canAfford(U.cost)
    }
    
    public func afford<U: Unit>(_ unit: U.Type, run: () -> ()) -> Bool {
        if !self.canAfford(U.cost) {
            return false
        }
        
        run()
        
        return true
    }
    
    public func train<U: Unit>(_ unit: U.Type, run: () -> ()) -> Bool {
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
        let sc2: SC2APIProtocol_Point
        
        public var x: Float { sc2.x }
        public var y: Float { sc2.y }
        public var z: Float { sc2.z }
        
        public func distanceXY(to coordinate: Self) -> Float {
            max(
                distance(inSpace: \.x, to: coordinate),
                distance(inSpace: \.y, to: coordinate)
            )
        }
        
        public func distance(inSpace space: KeyPath<Self, Float>, to coordinate: Self) -> Float {
            abs(coordinate[keyPath: space] - self[keyPath: space])
        }
    }
    
    public struct World2D {
        let sc2: SC2APIProtocol_Point2D
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
