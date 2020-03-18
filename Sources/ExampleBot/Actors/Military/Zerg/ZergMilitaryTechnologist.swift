import SC2Kit

final class ZergMilitaryTechnologist: StrategyActor {
    enum BuildingTech {
        case spawningPool
    }
    
    /// This strategy wants to claim all REMAINING drones for economy
    let claimOrder: UnitClaimOrder = .normal
    private var militaryTech = [UnitTag: BuildingTech]()
    private var techDrones = [UnitTag: BuildingTech]()
    var permanentClaims: [UnitTag] {
        Array(militaryTech.keys) + Array(techDrones.keys)
    }
    
    init() {}
    
    func claimUnits(from selection: inout [AnyUnit], contrainedBy budget: Cost, gamestate: GamestateHelper) -> [AnyUnit] {
        // Tech buildings
        let spawningPools = selection.claimType(.spawningPool)
        
        for spawningPool in spawningPools {
            militaryTech[spawningPool.tag] = .spawningPool
        }
        
        var selectedUnits = spawningPools
        
        // If wants to expand tech
        if spawningPools.isEmpty, let drone = selection.claimType(max: 1, .drone).first {
            selectedUnits.append(drone)
            techDrones[drone.tag] = .spawningPool
        } else {
            let affordableZerglings = budget / Zergling.cost
            selectedUnits += selection.claimType(max: affordableZerglings, .zergling)
        }
        
        return selectedUnits
    }
    
    private func findSpawningPoolPosition(near drone: SC2Unit<Drone>, gamestate: GamestateHelper) -> Position.World2D? {
        guard let expansion = gamestate.getClustersWithExpansion().nearest(
            to: drone.worldPosition.as2D,
            keyPath: \.1.as2D
        ) else {
            return nil
        }
        
        // TODO: 
        return nil
    }
    
    func enactStrategy(contrainedBy strategyConstraints: inout StrategyConstraints, gamestate: GamestateHelper) -> StrategyContinuationRecommendation {
        var buildingSpawningPool = militaryTech.values.contains(.spawningPool)
        
        for (tag, task) in techDrones {
            switch task {
            case .spawningPool:
                if
                    let drone = strategyConstraints.units.first(byTag: tag, as: Drone.self),
                    let position = findSpawningPoolPosition(near: drone, gamestate: gamestate)
                {
                    drone.buildSpawningPool(
                        at: position,
                        subbtracting: &strategyConstraints.budget
                    )
                    
                    buildingSpawningPool = true
                }
            }
        }
        
        for larva in strategyConstraints.units.all(Larva.self) {
            larva.trainZergling(subtracting: &strategyConstraints.budget)
        }
        
        if buildingSpawningPool {
            return .init(type: .prioritize, minimumRequestedBudget: SpawningPool.cost, maximumRequestedBudget: nil)
        } else {
            return .init(type: .proceed, minimumRequestedBudget: Zergling.cost, maximumRequestedBudget: nil)
        }
    }
}
