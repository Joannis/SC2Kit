protocol ProtossUnit: SC2Unit {}

extension ProtossUnit {
    public var shields: Float {
        sc2.shield
    }
    
    public var maxShields: Float {
        sc2.shield
    }
}

public struct Probe: ProtossUnit {
    public static let cost: Cost = .minerals(50)
    public static let supply = 0
    public static let type: UnitType = .probe
    
    let sc2: SC2APIProtocol_Unit
    let helper: GamestateHelper
    
    public init?(anyUnit: AnyUnit) {
        guard anyUnit.type == .probe else { return nil }
        self.sc2 = anyUnit.sc2
        self.helper = anyUnit.helper
    }
}
