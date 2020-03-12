import SC2Kit

final class EconomyCompoundStrategyActor: StrategyActor {
    /// This strategy wants to claim all REMAINING drones for economy
    let claimOrder: UnitClaimOrder = .last
    
    let expand = ExpansionStrategyActor()
    let worker = WorkerStrategyActor()
    
    private var expandUnits = [AnyUnit]()
    private var workerUnits = [AnyUnit]()
    
    init() {}
    
    func claimUnits(from selection: inout [AnyUnit], gamestate: GamestateHelper) -> [AnyUnit] {
        // Expand claims a drone first
        expandUnits = expand.claimUnits(from: &selection, gamestate: gamestate)
        workerUnits = worker.claimUnits(from: &selection, gamestate: gamestate)
        
        return expandUnits + workerUnits
    }
    
    func enactStrategy(contrainedBy strategyConstraints: inout StrategyConstraints, gamestate: GamestateHelper) -> StrategyContinuationRecommendation {
        strategyConstraints.units = workerUnits
        let enactWorkers = worker.enactStrategy(contrainedBy: &strategyConstraints, gamestate: gamestate)
        
        strategyConstraints.units = expandUnits
        let enactExpand = expand.enactStrategy(contrainedBy: &strategyConstraints, gamestate: gamestate)
        
        let priority = enactWorkers.type > enactExpand.type ? enactWorkers.type : enactExpand.type
        
        var minimumRequestedBudget: Cost? = nil
        var maximumRequestedBudget: Cost? = nil
        
        if let workersMin = enactWorkers.minimumRequestedBudget {
            if let expandMin = enactExpand.minimumRequestedBudget {
                minimumRequestedBudget = workersMin + expandMin
            } else {
                minimumRequestedBudget = workersMin
            }
        } else if let expandMin = enactExpand.minimumRequestedBudget {
            minimumRequestedBudget = expandMin
        }
        
        if let workersMax = enactWorkers.maximumRequestedBudget {
            if let expandMax = enactExpand.maximumRequestedBudget {
                maximumRequestedBudget = workersMax + expandMax
            } else {
                maximumRequestedBudget = workersMax
            }
        } else if let expandMax = enactExpand.maximumRequestedBudget {
            maximumRequestedBudget = expandMax
        }
        
        return StrategyContinuationRecommendation(
            type: priority,
            minimumRequestedBudget: minimumRequestedBudget,
            maximumRequestedBudget: maximumRequestedBudget
        )
    }
}
