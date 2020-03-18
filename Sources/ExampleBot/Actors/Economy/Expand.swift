import SC2Kit

final class ExpansionStrategyActor: StrategyActor {
    /// This strategy wants to claim all REMAINING drones for economy
    let claimOrder: UnitClaimOrder = .first
    private(set) var permanentClaims = [UnitTag]()
    
    func claimUnits(from selection: inout [AnyUnit], contrainedBy budget: Cost, gamestate: GamestateHelper) -> [AnyUnit] {
        if !budget.canAfford(Hatchery.self) {
            return []
        }
        
        return selection.claimType(max: 1, .drone)
    }
    
    init() {}
    
    func enactStrategy(contrainedBy strategyConstraints: inout StrategyConstraints, gamestate: GamestateHelper) -> StrategyContinuationRecommendation {
        func buildHatcheries() -> Bool {
            let isHeadingToExpansion = gamestate.units.owned(Drone.self).contains { drone in
                drone.orders.contains { $0.ability == .buildHatchery }
            }
            
            let isBuildingExpansion = gamestate.units.owned(Hatchery.self).contains { hatchery in
                hatchery.buildProgress < 1
            }
            
            guard
                !isHeadingToExpansion, !isBuildingExpansion,
                strategyConstraints.budget.canAfford(Hatchery.self),
                let drone = strategyConstraints.units.owned(Drone.self).first
            else {
                return false
            }
            
            // Detect current expansions and ignore those clusters
            let allClusters = gamestate.getClusters()
            let currentExpansions = gamestate.getClustersWithExpansion().map { $0.2 }
            
            var possibleExpansions = allClusters.compactMap { cluster -> (MineralCluster, Position.World, Float)? in
                for expansion in currentExpansions {
                    // Is already an expansion
                    if expansion.worldPosition.as2D.distanceXY(to: cluster.1.as2D) <= 15 {
                        return nil
                    }
                }
                
                var combinedDistance: Float = 0
                for expansion in currentExpansions {
                    combinedDistance += expansion.worldPosition.as2D.distanceXY(to: cluster.1.as2D)
                }
                
                return (cluster.0, cluster.1, combinedDistance / Float(currentExpansions.count))
            }
            
            possibleExpansions.sort { lhs, rhs in
                return lhs.2 < rhs.2
            }
            
            if let (_, position, _) = possibleExpansions.first {
                drone.buildHatchery(at: position.as2D, subbtracting: &strategyConstraints.budget)
            }
            
            return true
        }
        
        // TODO: Choose base closest to our current expansions
        // TODO: Expand when drones are filling up expansions
        
        // Return if it's not safe now
        // Return if we have no idle workers
        
        // Expand if we have Idle workers
        // Expand if we're floating too many minerals
        
        if !buildHatcheries() {
            // We don't need another hatchery now, stop claiming
            return StrategyContinuationRecommendation(
                type: .deprioritize,
                minimumRequestedBudget: nil,
                maximumRequestedBudget: nil
            )
        } else if WorkerStrategyActor.neededDrones(gamestate: gamestate) <= 3 {
            return StrategyContinuationRecommendation(
                type: .prioritize,
                minimumRequestedBudget: Hatchery.cost - strategyConstraints.budget,
                maximumRequestedBudget: nil
            )
        } else {
            return StrategyContinuationRecommendation(
                type: .deprioritize,
                minimumRequestedBudget: nil,
                maximumRequestedBudget: nil
            )
        }
    }
}
