import Foundation
import SC2Kit

enum UnitClaimOrder {
    case first, normal, last
}

enum FocusArea: Hashable {
    /// Build defensive units, position defensively
    case defense
    
    /// A final blow or putting emphesis on an opportunity
    case attack
    
    /// Find and exploit weak points
    case harass
    
    /// No room to build workers or army? Let's fix that!
    case expandSupply
    
    /// Look for technological advantages to further refine the focus areas
    case scout
    
    /// Expand production capabilities. For zergs this can be either marco bases or making extra expansions
    case expandProduction
    
    /// Either to catch up on economy or to gain more leverage
    case expandEconomy
    
    /// Either to catch up on technology or to gain more leverage
    case improveTechnologies
    
    func makeActor<AS: ActorSet>(from set: AS.Type) -> StrategyActor {
        switch self {
        case .expandEconomy:
            return AS.makeEconomyActor()
        case .expandSupply:
            return AS.makeSupplyActor()
        case .scout:
            return AS.makeScoutActor()
        case .attack:
            return AS.makeOffensiveActor()
        case .defense:
            return AS.makeDefensiveActor()
        default:
            fatalError()
        }
    }
}

protocol ActorSet {
    associatedtype ScoutActor: StrategyActor
    associatedtype EconomyActor: StrategyActor
    associatedtype SupplyActor: StrategyActor
    associatedtype OffensiveActor: StrategyActor
    associatedtype DefensiveActor: StrategyActor
    
    static func makeScoutActor() -> ScoutActor
    static func makeEconomyActor() -> EconomyActor
    static func makeSupplyActor() -> SupplyActor
    static func makeOffensiveActor() -> OffensiveActor
    static func makeDefensiveActor() -> DefensiveActor
}

protocol StrategyActor: class {
    var claimOrder: UnitClaimOrder { get }
    var permanentClaims: [UnitTag] { get }
    
    func claimUnits(from selection: inout [AnyUnit], contrainedBy budget: Cost, gamestate: GamestateHelper) -> [AnyUnit]
//    static func makeRecommendation(from selection: inout [AnyUnit], gamestate: GamestateHelper) -> [AnyUnit]
    func enactStrategy(contrainedBy strategyConstraints: inout StrategyConstraints, gamestate: GamestateHelper) -> StrategyContinuationRecommendation
}

struct StrategyContinuationRecommendation {
    let type: StrategyContinuationRecommendationType
    
    /// Given that this strategy takes on priority, what's the minimum needed to accomplish the goal
    var minimumRequestedBudget: Cost?
    
    /// Granted plenty of resources, and the ability to save. What would ideally be consumed for this task?
    var maximumRequestedBudget: Cost?
}

enum StrategyContinuationRecommendationType: Int {
    /// Urgent action is recommended
    /// Budget will be used, more budget is requested
    case prioritize = 4
    
    /// Proceeding will yield high benefits
    /// Budget will be used, recommendation is to add budget
    case proceed = 3
    
    /// Necessity is lost, but advantage can still be gained
    /// Recommendation is to reclaim granted budget
    case deprioritize = 2
    
    /// Putting in effort is a waste of time
    /// Budget will not be used
    case stop = 1
}

func >(lhs: StrategyContinuationRecommendationType, rhs: StrategyContinuationRecommendationType) -> Bool {
    lhs.rawValue > rhs.rawValue
}

extension Array where Element == AnyUnit {
    mutating func claimType(max: Int = .max, _ type: UnitType) -> [AnyUnit] {
        claim(max: max) { $0.type == type }
    }
    
    mutating func claim(max: Int = .max, _ run: (AnyUnit) -> Bool) -> [AnyUnit] {
        var unclaimed = [AnyUnit]()
        var claimed = [AnyUnit]()
        
        for unit in self {
            if claimed.count < max, run(unit) {
                claimed.append(unit)
            } else {
                unclaimed.append(unit)
            }
        }
        
        self = unclaimed
        return claimed
    }
}

extension GamestateHelper {
//    func enactStrategies(_ strategies: [StrategyRecommendation]) -> [StrategyConstraints] {
//        var units = self.units
//        let minerals = Float(self.economy.minerals)
//        let vespene = Float(self.economy.vespene)
//
//        return strategies.sorted(by: { $0.weight > $1.weight }).map { strategy in
//            let usedUnits = strategy.area.claimUnitIndices(from: &units)
//            let usedMinerals = Int(minerals / strategy.weight)
//            let usedVespene = Int(vespene / strategy.weight)
//
//            return StrategyConstraints(mineralBudget: usedMinerals, vespeneGasBudget: usedVespene, units: usedUnits)
//        }
//    }
}

struct StrategyConstraints {
    var units: [AnyUnit]
    var budget: Cost
}

struct StrategyRecommendation {
    let area: FocusArea
    let weight: Float
}
