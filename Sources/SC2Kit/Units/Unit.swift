public enum UnitType: UInt32 {
    case scv = 45
    
    case probe = 84
    
    case hatchery = 86
    case creepTumor = 87
    case extractor = 88
    case spawningPool = 89
    case evolutionChamber = 90
    case hydraliskDen = 91
    case spire = 92
    case ultraliskCavern = 93
    case infestationPit = 94
    case nydusNetwork = 95
    case banelingNest = 96
    case roachWarren = 97
    case spineCrawler = 98
    case sporeCrawler = 99
    case lair = 100
    case hive = 101
    case greaterSpire = 102
    case egg = 103
    case drone = 104
    case zergling = 105
    case overlord = 106
    case hydralisk = 107
    case mutalist = 108
    case ultralisk = 109
    case roach = 110
    case infestor = 111
    case corrutor = 112
    case broodlordCocoon = 113
    case broodlord = 114
    case burrowedBaneling = 115
    case burrowedDrone = 116
    case burrowedHydralisk = 117
    case burrowedRoach = 118
    case burrowedZergling = 119
    case burrowedInfestedTerran = 120
    // Critters 121..<125
    case burrowedQueen = 125
    case queen = 126
    case burrowedInfestor = 127
    case overlordCocoon = 128
    case overseer = 129
    
    case mineralField = 341
    case vespeneGeyser = 342
    case spacePlatformGeyser = 343
    case richVespeneGeyser = 344
    // 345..<471 random environment stuff
    case unbuildableRocks = 472
    case unbuildableBricks = 473
    case unbuildablePlates = 474
    case debris2x2 = 475
    case enemyPathingBlocker1x1 = 476
    case enemyPathingBlocker2x2 = 477
    case enemyPathingBlocker4x4 = 478
    case enemyPathingBlocker8x8 = 479
    case enemyPathingBlocker16x16 = 480
    // 481 = scopeTest
    // 482 = SentryACGluescreenDummy
    case hellbat = 484
    // 485 = CollapsibleTerranTowerDebris
    case debrisRampLeft = 486
    case debrisRampRight = 487
    case mothershipCore = 488
    case locust = 489
    // TODO: ...1942
}

public struct AnyUnit {
    let sc2: SC2APIProtocol_Unit
    let helper: GamestateHelper

    public var type: UnitType? {
        UnitType(rawValue: sc2.unitType)
    }
}

public extension Array where Element == AnyUnit {
    func only<U: Unit>(_ unit: U.Type) -> [U]  {
        self.filter { $0.type == U.type }.compactMap(U.init)
    }
}

public protocol Unit {
    static var cost: Cost { get }
    static var type: UnitType { get }
    
    init?(anyUnit: AnyUnit)
}

public protocol Building: Unit {}
