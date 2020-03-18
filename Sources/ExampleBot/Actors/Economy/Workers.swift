import SC2Kit

final class WorkerStrategyActor: StrategyActor {
    /// This strategy wants to claim all REMAINING drones for economy
    let claimOrder: UnitClaimOrder = .last
    private(set) var permanentClaims = [UnitTag]()
    
    static func neededDrones(gamestate: GamestateHelper) -> Int {
        if gamestate.economy.freeSupply == 0 {
            return 0
        }
        
        let neededDrones = gamestate.units.owned(Hatchery.self).reduce(0) {
            $0 + $1.idealHarvesters
        }
        // TODO: Vespene workers
        
        return neededDrones - currentDrones(gamestate: gamestate) // FIXME: hardcoded
    }
    
    static func currentDrones(gamestate: GamestateHelper) -> Int {
        let drones = gamestate.units.owned(Drone.self).count
        let morphing = gamestate.units.owned(Larva.self).filter { larva in
            larva.orders.contains { $0.ability == .trainDrone }
        }.count
        return drones + morphing
    }
    
    func claimUnits(from selection: inout [AnyUnit], contrainedBy budget: Cost, gamestate: GamestateHelper) -> [AnyUnit] {
        let affordableDrones = budget / Drone.cost
        let maxDrones = min(affordableDrones, Self.neededDrones(gamestate: gamestate))
        return selection.claimType(max: maxDrones, .larva)
    }
    
    init() {}
    
    func enactStrategy(contrainedBy strategyConstraints: inout StrategyConstraints, gamestate: GamestateHelper) -> StrategyContinuationRecommendation {
        let larva = strategyConstraints.units.owned(Larva.self)
        let neededDrones = Self.neededDrones(gamestate: gamestate)
        var trained = 0
        for larva in larva where trained < neededDrones {
            if larva.trainDrone(subtracting: &strategyConstraints.budget) {
                trained += 1
            }
        }
        
        let totalDrones = Self.currentDrones(gamestate: gamestate) + trained
        
        // No supply makes this kinda useless to do
        if gamestate.economy.freeSupply == 0 {
            return StrategyContinuationRecommendation(
                type: .stop,
                minimumRequestedBudget: nil,
                maximumRequestedBudget: nil
            )
        } else if gamestate.economy.freeSupply == 1 {
            return StrategyContinuationRecommendation(
                type: totalDrones < 20 ? .proceed : .deprioritize,
                minimumRequestedBudget: nil,
                maximumRequestedBudget: nil
            )
        }
        
        switch totalDrones {
        case ..<35:
            return StrategyContinuationRecommendation(
                type: .prioritize,
                minimumRequestedBudget: Drone.cost,
                maximumRequestedBudget: nil
            )
        case 35..<65:
            return StrategyContinuationRecommendation(
                type: .proceed,
                minimumRequestedBudget: nil,
                maximumRequestedBudget: nil
            )
        case 65..<80:
            return StrategyContinuationRecommendation(
                type: .deprioritize,
                minimumRequestedBudget: nil,
                maximumRequestedBudget: nil
            )
        case 80...:
            return StrategyContinuationRecommendation(
                type: .stop,
                minimumRequestedBudget: nil,
                maximumRequestedBudget: nil
            )
        default:
            assertionFailure("Invalid scenario")
            return StrategyContinuationRecommendation(
                type: .proceed,
                minimumRequestedBudget: nil,
                maximumRequestedBudget: nil
            )
        }
    }
}
