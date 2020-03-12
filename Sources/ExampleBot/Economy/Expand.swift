import SC2Kit

final class ExpansionStrategyActor: StrategyActor {
    /// This strategy wants to claim all REMAINING drones for economy
    let claimOrder: UnitClaimOrder = .last
    
    func claimUnits(from selection: inout [AnyUnit], gamestate: GamestateHelper) -> [AnyUnit] {
        return selection.claimType(max: 1, .drone)
    }
    
    init() {}
    
    func enactStrategy(contrainedBy strategyConstraints: inout StrategyConstraints, gamestate: GamestateHelper) -> StrategyContinuationRecommendation {
        func buildHatcheries() {
            var drones = strategyConstraints.units.only(Drone.self)
            
            let isExpanding = drones.contains { drone in
                drone.orders.contains { $0.ability == .buildHatchery }
            }
            
            guard
                !isExpanding,
                strategyConstraints.budget.canAfford(Hatchery.self),
                !drones.isEmpty
            else {
                return
            }
            
            // Detect current expansions and ignore those clusters
            let allClusters = gamestate.getClustersWithExpansion()
            let currentExpansions = allClusters.map { $0.2 }
            // Claim drone out of the pool so other tasks can't claim it
            let drone = drones.removeFirst()
            
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
        }
        
        // TODO: Choose base closest to our current expansions
        // TODO: Expand when drones are filling up expansions
        
        // Return if it's not safe now
        // Return if we have no idle workers
        
        // Expand if we have Idle workers
        // Expand if we're floating too many minerals
        
        buildHatcheries()
        return StrategyContinuationRecommendation(
            type: .proceed,
            minimumRequestedBudget: Hatchery.cost - strategyConstraints.budget,
            maximumRequestedBudget: nil
        )
    }
}
