public struct Minerals: _SC2Unit {
    let sc2: SC2APIProtocol_Unit
    let helper: GamestateHelper
    
    public init?(anyUnit: AnyUnit) {
        guard anyUnit.type?.isMinerals == true else { return nil }
        self.sc2 = anyUnit.sc2
        self.helper = anyUnit.helper
    }
    
    public var mineralContents: Int {
        Int(sc2.mineralContents)
    }
}

extension Array where Element == AnyUnit {
    public var minerals: [Minerals] {
        self.filter { $0.type?.isMinerals == true }.compactMap(Minerals.init)
    }
}
