// - MARK: Units
public protocol ZergLarvaUnit: Entity {
    static var trainAbility: Ability { get }
}

public protocol ZergDroneBuilding: Building {
    static var buildAbility: Ability { get }
}

extension SC2Unit where E: ZergLarvaUnit {
    public var isBurrowed: Bool { sc2.isBurrowed }
}

public enum Drone: ZergLarvaUnit {
    public static let cost: Cost = .minerals(50)
    public static let supply = 1
    public static let type: UnitType = .drone
    public static let trainAbility = Ability.trainDrone
}

public enum Zergling: ZergLarvaUnit {
    public static let cost: Cost = .minerals(50)
    public static let supply = 1
    public static let type: UnitType = .zergling
    public static let trainAbility = Ability.trainZergling
}

extension SC2Unit where E == Drone {
    public func harvest(_ unit: SC2Unit<Minerals>) {
        helper.actions.append(.commandUnits([self.tag], do: .gather, on: .unit(unit.tag), queued: false))
    }
    
    public func buildSpawningPool(at position: Position.World2D, subbtracting budget: inout Cost) {
        budget.afford(Hatchery.self) {
            let placement = PlaceBuilding(
                unit: self.tag,
                ability: .buildSpawningPool,
                ignoreResourceRequirements: true,
                position: position
            ) { gamestate in
                gamestate.actions.append(.commandUnits([self.tag], do: .buildSpawningPool, on: .position(position), queued: false))
            }
            
            helper.placedBuildings.append(placement)
        }
    }
    
    public func buildHatchery(at position: Position.World2D, subbtracting budget: inout Cost) {
        budget.afford(Hatchery.self) {
            let placement = PlaceBuilding(
                unit: self.tag,
                ability: .buildHatchery,
                ignoreResourceRequirements: true,
                position: position
            ) { gamestate in
                gamestate.actions.append(.commandUnits([self.tag], do: .buildHatchery, on: .position(position), queued: false))
            }
            
            helper.placedBuildings.append(placement)
        }
    }
}

public enum Overlord: ZergLarvaUnit {
    public static let cost: Cost = .minerals(100)
    public static let supply = 0
    public static let type: UnitType = .overlord
    public static let trainAbility = Ability.trainOverlord
}

public enum Larva: Entity {
    public static var cost: Cost = .none
    public static let supply = 0
    public static let type: UnitType = .larva
}

extension SC2Unit where E == Larva {
    @discardableResult
    public func trainZergling(subtracting budget: inout Cost) -> Bool {
        spawn(into: Zergling.self, subtracting: &budget)
    }
    
    @discardableResult
    public func trainDrone(subtracting budget: inout Cost) -> Bool {
        spawn(into: Drone.self, subtracting: &budget)
    }
    
    @discardableResult
    public func trainOverlord(subtracting budget: inout Cost) -> Bool {
        spawn(into: Overlord.self, subtracting: &budget)
    }
    
    private func spawn<Z: ZergLarvaUnit>(into entity: Z.Type, subtracting budget: inout Cost) -> Bool {
        budget.afford(Z.self) {
            helper.actions.append(.commandUnits([self.tag], do: Z.trainAbility, on: .none, queued: false))
        }
    }
}

public enum Egg: Entity {
    public static let cost: Cost = .none
    public static let supply = 0
    public static var type: UnitType = .egg
}

extension SC2Unit where E == Egg {
    public var spawningInto: UnitType? {
        for order in sc2.orders {
            if let trainedUnit = Ability(rawValue: Int32(order.abilityID))?.trainedUnit {
                return trainedUnit
            }
        }
        
        return nil
    }
}

extension Array where Element == SC2Unit<Egg> {
    public func spawning(into type: UnitType) -> [SC2Unit<Egg>] {
        filter { $0.spawningInto == type }
    }
}

// - MARK: Buildings

public enum Hatchery: ZergDroneBuilding {
    public static let cost: Cost = .minerals(300)
    public static let creepPlacement = CreepPlacement.optional
    public static let positioning: ClosedRange<Int> = -2...2
    public static let supply = 0
    public static let type: UnitType = .hatchery
    public static let buildAbility = Ability.buildHatchery
}

public enum SpawningPool: ZergDroneBuilding {
    public static let cost: Cost = .minerals(200)
    public static let creepPlacement = CreepPlacement.requires(true)
    public static let positioning: ClosedRange<Int> = -1...1
    public static let supply = 0
    public static let type: UnitType = .spawningPool
    public static let buildAbility = Ability.buildSpawningPool
}

extension SC2Unit where E == Hatchery {
    public var idealHarvesters: Int {
        Int(sc2.idealHarvesters)
    }
    
    public var assignedHarvesters: Int {
        Int(sc2.assignedHarvesters)
    }
    
    public var harvesterSurplus: Int {
        assignedHarvesters - idealHarvesters
    }

//    FIXME: This code triggers notSupported, probably the wrong ability code
//    public func rallyWorkers(to target: Target) {
//        helper.actions.append(.commandUnits([self.tag], .rallyWorkers, target))
//    }
//
//    public func rallyWorkers(to resource: SC2Unit<Resources>) {
//        rallyWorkers(to: .unit(resource.tag))
//    }
//
//    public func rallyWorkers(to minerals: SC2Unit<Minerals>) {
//        rallyWorkers(to: .unit(minerals.tag))
//    }
//
//    public func rallyWorkers(to vespeneGeyser: SC2Unit<VespeneGeyser>) {
//        rallyWorkers(to: .unit(vespeneGeyser.tag))
//    }
}
