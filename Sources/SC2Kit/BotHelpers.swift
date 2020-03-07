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
    
    public func canAfford(_ cost: Cost) -> Bool {
        if cost.minerals < observation.player.minerals {
            return false
        }
        
        if cost.vespene < observation.player.vespene {
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
