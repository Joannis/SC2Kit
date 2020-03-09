public protocol ProtossUnit: Entity {}

extension SC2Unit where E: ProtossUnit {
    public var shields: Float { sc2.shield }
    public var maxShields: Float { sc2.shieldMax }
}

public enum Probe: ProtossUnit {
    public static let cost: Cost = .minerals(50)
    public static let supply = 0
    public static let type: UnitType = .probe
}
