// - MARK: Units
protocol ZergLarvaUnit: SC2Unit {
    static var trainAbility: Ability { get }
}

extension ZergLarvaUnit {
    public var isBurrowed: Bool { sc2.isBurrowed }
}

public struct Drone: ZergLarvaUnit {
    public static let cost: Cost = .minerals(50)
    public static let supply = 1
    public static let type: UnitType = .drone
    static let trainAbility = Ability.trainDrone
    
    let sc2: SC2APIProtocol_Unit
    let helper: GamestateHelper
    
    public init?(anyUnit: AnyUnit) {
        guard anyUnit.type == Self.type else { return nil }
        self.sc2 = anyUnit.sc2
        self.helper = anyUnit.helper
    }
}

public struct Overlord: ZergLarvaUnit {
    public static let cost: Cost = .minerals(100)
    public static let supply = 0
    public static let type: UnitType = .overlord
    static let trainAbility = Ability.trainOverlord
    
    let sc2: SC2APIProtocol_Unit
    let helper: GamestateHelper
    
    public init?(anyUnit: AnyUnit) {
        guard anyUnit.type == Self.type else { return nil }
        self.sc2 = anyUnit.sc2
        self.helper = anyUnit.helper
    }
}

public struct Larva: SC2Unit {
    public static var cost: Cost = .none
    public static let supply = 0
    public static let type: UnitType = .larva
    
    let sc2: SC2APIProtocol_Unit
    let helper: GamestateHelper
    
    public init?(anyUnit: AnyUnit) {
        guard anyUnit.type == Self.type else { return nil }
        self.sc2 = anyUnit.sc2
        self.helper = anyUnit.helper
    }
    
    public func trainDrone() -> Bool {
        spawn(into: Drone.self)
    }
    
    public func trainOverlord() -> Bool {
        spawn(into: Overlord.self)
    }
    
    private func spawn<Z: ZergLarvaUnit>(into entity: Z.Type) -> Bool {
        return helper.train(Z.self) {
            helper.actions.append(.commandUnits([self.tag], Z.trainAbility))
        }
    }
}

public struct Egg: SC2Unit {
    public static let cost: Cost = .none
    public static let supply = 0
    public static var type: UnitType = .egg
    
    let sc2: SC2APIProtocol_Unit
    let helper: GamestateHelper
    
    public init?(anyUnit: AnyUnit) {
        guard anyUnit.type == Self.type else { return nil }
        self.sc2 = anyUnit.sc2
        self.helper = anyUnit.helper
    }
    
    public var spawningInto: UnitType? {
        for order in sc2.orders {
            if let trainedUnit = Ability(rawValue: Int32(order.abilityID))?.trainedUnit {
                return trainedUnit
            }
        }
        
        return nil
    }
}

extension Array where Element == Egg {
    public func spawning(into type: UnitType) -> [Egg] {
        filter { $0.spawningInto == type }
    }
}

// - MARK: Buildings

public struct Hatchery: SC2Building {
    public static let cost: Cost = .minerals(300)
    public static let supply = 0
    public static let type: UnitType = .hatchery
    
    let sc2: SC2APIProtocol_Unit
    let helper: GamestateHelper
    
    public init?(anyUnit: AnyUnit) {
        guard anyUnit.type == Self.type else { return nil }
        self.sc2 = anyUnit.sc2
        self.helper = anyUnit.helper
    }
    
    public var idealHarvesters: Int {
        Int(sc2.idealHarvesters)
    }
    
    public var assignedHarvesters: Int {
        Int(sc2.assignedHarvesters)
    }
    
    public var harvesterSurplus: Int {
        assignedHarvesters - idealHarvesters
    }
}
