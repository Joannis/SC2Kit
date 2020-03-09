public struct Minerals: AnyEntity {}

extension SC2Unit where E == Minerals {
    public var mineralContents: Int {
        Int(sc2.mineralContents)
    }
}

extension Array where Element == AnyUnit {
    public var minerals: [SC2Unit<Minerals>] {
        self.filter { $0.type?.isMinerals == true }.compactMap(SC2Unit<Minerals>.init)
    }
}
