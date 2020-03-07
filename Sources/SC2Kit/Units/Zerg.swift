// - MARK: Units

public struct Drone: Unit {
    public static let cost: Cost = .minerals(50)
    public static let type: UnitType = .drone
    
    let sc2: SC2APIProtocol_Unit
    let helper: GamestateHelper
    
    public init?(anyUnit: AnyUnit) {
        guard anyUnit.type == .drone else { return nil }
        self.sc2 = anyUnit.sc2
        self.helper = anyUnit.helper
    }
}

// - MARK: Buildings

public struct Hatchery: Building {
    public static let cost: Cost = .minerals(50)
    public static let type: UnitType = .hatchery
    
    let sc2: SC2APIProtocol_Unit
    let helper: GamestateHelper
    
    public init?(anyUnit: AnyUnit) {
        guard anyUnit.type == .drone else { return nil }
        self.sc2 = anyUnit.sc2
        self.helper = anyUnit.helper
    }
    
    public func buildDrone() {
        helper.actions.append(.commandUnit(() as! Ability, .none))
    }
}
