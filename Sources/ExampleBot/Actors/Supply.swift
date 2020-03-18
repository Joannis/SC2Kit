import SC2Kit

final class SupplyStrategyActor: StrategyActor {
    /// This strategy wants to claim all REMAINING drones for economy
    let claimOrder: UnitClaimOrder = .first
    private(set) var permanentClaims = [UnitTag]()
    
    static func neededOverlords(gamestate: GamestateHelper) -> Int {
        let overlords = gamestate.units.owned(Overlord.self).count
        let spawning = gamestate.units.owned(Larva.self).filter { larva in
            larva.orders.contains { $0.ability == .trainOverlord }
        }.count
        
        let currentOverlords = overlords + spawning
        return wantedOverlords(gamestate: gamestate) - currentOverlords
    }
    
    static func wantedOverlords(gamestate: GamestateHelper) -> Int {
        return (gamestate.economy.usedSupply / 7 + 1)
    }
    
    func claimUnits(from selection: inout [AnyUnit], contrainedBy budget: Cost, gamestate: GamestateHelper) -> [AnyUnit] {
        // Ensure not to claim too many larva if they aren't being used
        let affordableOverlords = budget / Overlord.cost
        let maxClaim = min(affordableOverlords, Self.neededOverlords(gamestate: gamestate))
        return selection.claimType(max: maxClaim, .larva)
    }
    
    init() {}
    
    func enactStrategy(contrainedBy strategyConstraints: inout StrategyConstraints, gamestate: GamestateHelper) -> StrategyContinuationRecommendation {
        let larva = strategyConstraints.units.owned(Larva.self)
        for larva in larva {
            larva.trainOverlord(subtracting: &strategyConstraints.budget)
        }
        let neededOverlords = Self.neededOverlords(gamestate: gamestate)
        
        // TODO: Choose base closest to our current expansions
        
        // Return if it's not safe now
        // Return if we have no idle workers
        
        // Expand if we have Idle workers
        // Expand if we're floating too many minerals
        
        switch neededOverlords {
        case 2...:
            return StrategyContinuationRecommendation(
                type: .prioritize,
                minimumRequestedBudget: nil,
                maximumRequestedBudget: nil
            )
        case 1:
            return StrategyContinuationRecommendation(
                type: .proceed,
                minimumRequestedBudget: nil,
                maximumRequestedBudget: nil
            )
        case 0:
            return StrategyContinuationRecommendation(
                type: .deprioritize,
                minimumRequestedBudget: nil,
                maximumRequestedBudget: nil
            )
        default:
            return StrategyContinuationRecommendation(
                type: .stop,
                minimumRequestedBudget: nil,
                maximumRequestedBudget: nil
            )
        }
    }
}
