public enum Resources: AnyEntity {
    case minerals(SC2Unit<Minerals>)
    case vespeneGeyser(SC2Unit<VespeneGeyser>)
}

public struct Minerals: AnyEntity {}
public struct VespeneGeyser: AnyEntity {}

extension SC2Unit where E == Minerals {
    public var mineralContents: Int {
        Int(sc2.mineralContents)
    }
}

extension Array where Element == AnyUnit {
    public var minerals: [SC2Unit<Minerals>] {
        self.compactMap { anyUnit in
            if anyUnit.type?.isMinerals == true {
                return SC2Unit<Minerals>(anyUnit: anyUnit)
            } else {
                return nil
            }
        }
    }
    
    public var vespeneGeysers: [SC2Unit<VespeneGeyser>] {
        self.compactMap { anyUnit in
            if anyUnit.type?.isVespeneGeyser == true {
                return SC2Unit<VespeneGeyser>(anyUnit: anyUnit)
            } else {
                return nil
            }
        }
    }
    
    public var resources: [SC2Unit<Resources>] {
        self.filter { $0.type?.isVespeneGeyser == true || $0.type?.isMinerals == true }.compactMap(SC2Unit<Resources>.init)
    }   
}

extension Array where Element == SC2Unit<Resources> {
    public var minerals: [SC2Unit<Minerals>] {
        self.compactMap(\.minerals)
    }
    
    public var vespeneGeysers: [SC2Unit<VespeneGeyser>] {
        self.compactMap(\.vespeneGeyser)
    }
}

extension SC2Unit where E == Resources {
    public var isMinerals: Bool {
        UnitType(rawValue: sc2.unitType)?.isMinerals == true
    }
    
    public var isVespeneGeyser: Bool {
        UnitType(rawValue: sc2.unitType)?.isVespeneGeyser == true
    }
    
    public var minerals: SC2Unit<Minerals>? {
        if isMinerals {
            return SC2Unit<Minerals>(sc2: sc2, helper: helper)
        }
        
        return nil
    }
    
    public var vespeneGeyser: SC2Unit<VespeneGeyser>? {
        if isVespeneGeyser {
            return SC2Unit<VespeneGeyser>(sc2: sc2, helper: helper)
        }
        
        return nil
    }

    public var resources: Resources {
        if let geyser = self.vespeneGeyser {
            return .vespeneGeyser(geyser)
        } else if let minerals = self.minerals {
            return .minerals(minerals)
        } else {
            fatalError("Invalid resource")
        }
    }
}
