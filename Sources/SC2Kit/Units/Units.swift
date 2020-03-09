public struct AnyUnit {
    let sc2: SC2APIProtocol_Unit
    let helper: GamestateHelper

    public var type: UnitType? {
        UnitType(rawValue: sc2.unitType)
    }
    
    public var isFriendly: Bool {
        sc2.alliance == .ally
    }
    
    public var isEnemy: Bool {
        sc2.alliance == .enemy
    }
    
    public var isNeutral: Bool {
        sc2.alliance == .neutral
    }
}

extension Array where Element == AnyUnit {
    public var friendly: [AnyUnit] {
        self.filter { $0.isFriendly }
    }
    
    public var neutral: [AnyUnit] {
        self.filter { $0.isNeutral }
    }
    
    public var enemy: [AnyUnit] {
        self.filter { $0.isEnemy }
    }
    
    public func only<U: Entity>(_ unit: U.Type) -> [SC2Unit<U>]  {
        self.filter { $0.type == U.type }.compactMap(SC2Unit<U>.init)
    }
}

public struct SC2Unit<E: AnyEntity> {
    let sc2: SC2APIProtocol_Unit
    let helper: GamestateHelper
    
    init(
        sc2: SC2APIProtocol_Unit,
        helper: GamestateHelper
    ) {
        self.sc2 = sc2
        self.helper = helper
    }
    
    init?(anyUnit: AnyUnit) {
        self.sc2 = anyUnit.sc2
        self.helper = anyUnit.helper
    }
    
    public var isVisible: Bool {
        sc2.displayType == .visible
    }
    
    public var isHidden: Bool {
        sc2.displayType == .hidden
    }
    
    public var worldPosition: Position.World {
        Position.World(sc2: sc2.pos)
    }
    
    public var tag: UnitTag {
        UnitTag(tag: sc2.tag)
    }
    
    public var health: Float {
        sc2.health
    }
    
    public var maxHealth: Float {
        sc2.healthMax
    }
    
    public var isFriendly: Bool {
        sc2.alliance == .ally
    }
    
    public var isEnemy: Bool {
        sc2.alliance == .enemy
    }
    
    public var isNeutral: Bool {
        sc2.alliance == .neutral
    }
    
    public var orders: [Order] {
        sc2.orders.map(Order.init)
    }
}

public struct Order {
    let sc2: SC2APIProtocol_UnitOrder
    
    public var ability: Ability? {
        Ability(rawValue: Int32(sc2.abilityID))
    }
}

public protocol AnyEntity {}
public protocol Entity: AnyEntity {
    static var cost: Cost { get }
    static var type: UnitType { get }
    static var supply: Int { get }
}

public protocol Building: Entity {}

extension SC2Unit where E: Building {
    public var buildProgress: Float {
        sc2.buildProgress
    }
}

public enum UnitType: UInt32 {
    case scv = 45
    case hellbat = 484
    
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
    case larva = 151
    case locust = 489
    
    case unbuildableRocks = 472
    case unbuildableBricks = 473
    case unbuildablePlates = 474
    case debris2x2 = 475
    case enemyPathingBlocker1x1 = 476
    case enemyPathingBlocker2x2 = 477
    case enemyPathingBlocker4x4 = 478
    case enemyPathingBlocker8x8 = 479
    case enemyPathingBlocker16x16 = 480
    case debrisRampLeft = 486
    case debrisRampRight = 487
    case mothershipCore = 488
    
    case battlestationMineralField = 886
    case battlestationMineralField750 = 887
    case forcefield = 135
    case labMineralField = 665
    case labMineralField750 = 666
    case mineralField = 341
    case mineralField750 = 483
    case protossVespeneGeyser = 608
    case purifierMineralField = 884
    case purifierMineralField750 = 885
    case purifierRichMineralField = 796
    case purifierRichMineralField750 = 797
    case purifierVespeneGeyser = 880
    case richMineralField = 146
    case richMineralField750 = 147
    case richVespeneGeyser = 344
    case shakurasVespeneGeyser = 881
    case spacePlatformGeyser = 343
    case vespeneGeyser = 342
    
    case xelnagaTower = 149
    
    public var isMinerals: Bool {
        switch self {
        case .mineralField, .mineralField750, .battlestationMineralField, .battlestationMineralField750, .labMineralField, .labMineralField750, .purifierMineralField, .purifierMineralField750, .purifierRichMineralField, .purifierRichMineralField750, .richMineralField, .richMineralField750:
            return true
        default:
            return false
        }
    }
    
    public var isRichMinerals: Bool {
        switch self {
        case .purifierRichMineralField, .purifierRichMineralField750, .richMineralField, .richMineralField750:
            return true
        default:
            return false
        }
    }
    
    public var isVespeneGeyser: Bool {
        switch self {
        case .vespeneGeyser, .protossVespeneGeyser, .spacePlatformGeyser, .purifierVespeneGeyser, .shakurasVespeneGeyser, .richVespeneGeyser:
            return true
        default:
            return false
        }
    }
    
    public var isRichVespeneGeyser: Bool {
        self == .richVespeneGeyser
    }
}
