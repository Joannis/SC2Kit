import SC2Kit

final class WorkerStrategyActor: StrategyActor {
    /// This strategy wants to claim all REMAINING drones for economy
    let claimOrder: UnitClaimOrder = .last
    
    static func neededDrones(gamestate: GamestateHelper) -> Int {
        return 75 - currentDrones(gamestate: gamestate) // FIXME: hardcoded
    }
    
    static func currentDrones(gamestate: GamestateHelper) -> Int {
        let drones = gamestate.units.only(Drone.self).count
        let morphing = gamestate.units.only(Larva.self).filter { larva in
            larva.orders.contains { $0.ability == .trainDrone }
        }.count
        return drones + morphing
    }
    
    func claimUnits(from selection: inout [AnyUnit], gamestate: GamestateHelper) -> [AnyUnit] {
        return selection.claimType(max: Self.neededDrones(gamestate: gamestate), .larva)
    }
    
    init() {}
    
    func enactStrategy(contrainedBy strategyConstraints: inout StrategyConstraints, gamestate: GamestateHelper) -> StrategyContinuationRecommendation {
        let larva = strategyConstraints.units.only(Larva.self)
        let neededDrones = Self.neededDrones(gamestate: gamestate)
        var trained = 0
        for larva in larva where trained < neededDrones {
            if larva.trainDrone(substracting: &strategyConstraints.budget) {
                trained += 1
            }
        }
        
        let totalDrones = Self.currentDrones(gamestate: gamestate) + trained
        
        // TODO: Cap drones to needed by expansions
        
        switch totalDrones {
        case ..<35:
            return StrategyContinuationRecommendation(
                type: .prioritize,
                minimumRequestedBudget: nil,
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
