public struct Probe: Unit {
    public static let cost: Cost = .minerals(50)
    public static let type: UnitType = .probe
    
    let sc2: SC2APIProtocol_Unit
    let helper: GamestateHelper
    
    public init?(anyUnit: AnyUnit) {
        guard anyUnit.type == .probe else { return nil }
        self.sc2 = anyUnit.sc2
        self.helper = anyUnit.helper
    }
}
