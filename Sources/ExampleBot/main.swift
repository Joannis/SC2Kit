import Foundation
import SC2Kit

final class CustomBot: BotPlayer {
    func saveReplay(_ data: Data) {}
    var debugCommands = [DebugCommand]()
    var expanding: Position.World2D?
    var assignedConstraints = [FocusArea: StrategyConstraints]()
    var strategyActors = [FocusArea: StrategyActor]()
    
    init() {}
    
    func setupDebug(gamestate: GamestateHelper) {
        if !debugCommands.isEmpty {
            return
        }
        
//        #if DEBUG
//        nextCluster: for (cluster, expansionPosition) in getClusters(gamestate: gamestate) {
//            debugCommands.append(.draw([
//                .sphere(.init(at: cluster.approximateExpansionLocation, range: 3, color: .red)),
//                .sphere(.init(at: expansionPosition, range: 5, color: .red)),
//            ]))
//
//            debugCommands.append(.draw(cluster.resources.map { resource in
//                let distance = resource.worldPosition.as2D.distanceXY(to: expansionPosition.as2D)
//                return .text(DebugString(text: "\(distance)", color: .white, position: .world(resource.worldPosition)))
//            }))
//        }
//        #endif
    }
    
    func debug() -> [DebugCommand] {
        return debugCommands
    }
    
    func balanceEconomy(gamestate: GamestateHelper) {
        let expansions = gamestate.getClustersWithExpansion()
        let drones = gamestate.units.owned.only(Drone.self)
        var idleDrones = drones.filter { $0.orders.isEmpty }
        
        nextExpansion: for (_, _, hatchery) in expansions where !idleDrones.isEmpty {
            // Too many harvesters. Add some as idle
            var surplus = hatchery.harvesterSurplus
            
            nextDrone: for drone in drones where !drone.orders.isEmpty && surplus > 0 {
                for order in drone.orders where order.target == hatchery.tag {
                    surplus -= 1
                    idleDrones.append(drone)
                    continue nextDrone
                }
            }
        }
        
        var underCapacityExpansions = expansions.compactMap { cluster, position, hatchery -> (MineralCluster, Position.World, SC2Unit<Hatchery>, Int)? in
            if hatchery.harvesterSurplus >= 0 {
                return nil
            }
            
            return (cluster, position, hatchery, -hatchery.harvesterSurplus)
        }
        
        for _ in 0..<idleDrones.count {
            let assignedDrone = idleDrones.removeLast()
            let nearestIndex = underCapacityExpansions.nearestIndex(
                to: assignedDrone.worldPosition.as2D,
                keyPath: \.1.as2D
            )
            
            guard let index = nearestIndex else {
                // No more expansions means no need to schedule drones
                return
            }

            guard let minerals = underCapacityExpansions[index].0.resources.minerals.randomElement() else {
                assertionFailure("Empty expansion shouldn't be grouped as an expansion")
                return
            }
            
            assignedDrone.harvest(minerals)
            underCapacityExpansions[index].3 -= 1
            
            // Expansion is now satisfied
            if underCapacityExpansions[index].3 == 0 {
                underCapacityExpansions.remove(at: index)
            }
        }
    }
    
    func analyzeFocusAreas() -> [StrategyRecommendation] {
        return [
            StrategyRecommendation(area: .expandEconomy, weight: 1),
            StrategyRecommendation(area: .expandSupply, weight: 1)
        ]
    }
    
    func runTick(gamestate: GamestateHelper) {
        setupDebug(gamestate: gamestate)
        
        // This runs first, so that its commands are sent before being overridden by the strategies
        balanceEconomy(gamestate: gamestate)
        
        let recommendations = analyzeFocusAreas()
        var claimedMinerals = 0
        var claimedVespene = 0
        
        for constraint in assignedConstraints.values {
            claimedMinerals += constraint.budget.minerals
            claimedVespene += constraint.budget.vespene
        }
        
        let unclaimedMinerals = gamestate.economy.minerals - claimedMinerals
        let unclaimedVespene = gamestate.economy.vespene - claimedVespene
        
        assert(unclaimedMinerals >= 0)
        assert(unclaimedVespene >= 0)
        
        var reclaimedMinerals = 0
        var reclaimedVespene = 0
        
        var units = gamestate.units
        var claimedUnits = [FocusArea: [AnyUnit]]()
        
        let actors = recommendations.map { recommendation -> (FocusArea, StrategyActor) in
            if let actor = strategyActors[recommendation.area] {
                return (recommendation.area, actor)
            } else {
                let actor = recommendation.area.makeActor()
                strategyActors[recommendation.area] = actor
                return (recommendation.area, actor)
            }
        }
        
        for (area, actor) in actors where actor.claimOrder == .first {
            claimedUnits[area] = actor.claimUnits(from: &units, gamestate: gamestate)
        }
        
        for (area, actor) in actors where actor.claimOrder == .normal {
            claimedUnits[area] = actor.claimUnits(from: &units, gamestate: gamestate)
        }
        
        for (area, actor) in actors where actor.claimOrder == .last {
            claimedUnits[area] = actor.claimUnits(from: &units, gamestate: gamestate)
        }
        
        var results = [FocusArea: StrategyContinuationRecommendation]()
        
        for (focusArea, actor) in strategyActors {
            let isFocusArea = recommendations.contains(where: { $0.area == focusArea })
            
            if !isFocusArea {
                if let constraint = assignedConstraints[focusArea] {
                    reclaimedMinerals += constraint.budget.minerals
                    reclaimedVespene += constraint.budget.vespene
                }

                assignedConstraints[focusArea] = nil
                strategyActors[focusArea] = nil
            } else if let constraint = assignedConstraints[focusArea] {
                var constraint = constraint
                constraint.units = claimedUnits[focusArea] ?? []
                results[focusArea] = actor.enactStrategy(contrainedBy: &constraint, gamestate: gamestate)
                assignedConstraints[focusArea] = constraint
            } else {
                var constraint = StrategyConstraints(units: claimedUnits[focusArea] ?? [], budget: .none)
                results[focusArea] = actor.enactStrategy(contrainedBy: &constraint, gamestate: gamestate)
                assignedConstraints[focusArea] = constraint
            }
        }
        
        for (focusArea, result) in results where result.type == .stop {
            if let constraint = assignedConstraints[focusArea] {
                reclaimedMinerals += constraint.budget.minerals
                reclaimedVespene += constraint.budget.vespene
            }
            assignedConstraints[focusArea] = nil
            strategyActors[focusArea] = nil
        }
        
        var assignableMinerals = reclaimedMinerals + unclaimedMinerals
        var assignableVespene = reclaimedVespene + unclaimedVespene
        
        var claimableMinerals = 0
        var claimableVespene = 0
        
        for (focusArea, result) in results where result.type == .deprioritize {
            if let constraint = assignedConstraints[focusArea] {
                claimableMinerals += constraint.budget.minerals
                claimableVespene += constraint.budget.vespene
            }
        }
        
        func maxAssignableMinerals() -> Int { assignableMinerals + claimableMinerals }
        func maxAssignableVespene() -> Int { assignableVespene + claimableVespene }
        
        /// Claims vespene from unused resources
        /// Reclaims from open budgets to shift priorities if needed
        func claimMinerals(_ claim: Int) -> Int {
            if assignableMinerals > claim {
                assignableMinerals -= claim
                return claim
            } else {
                var unclaimed = claim - assignableMinerals
                assignableMinerals = 0
                
                for (focusArea, result) in results where result.type == .deprioritize && unclaimed > 0 {
                    if var constraint = assignedConstraints[focusArea] {
                        if constraint.budget.minerals >= unclaimed {
                            constraint.budget.minerals -= unclaimed
                            unclaimed = 0
                            return claim
                        } else {
                            unclaimed -= constraint.budget.minerals
                            constraint.budget.minerals = 0
                        }
                        
                        assignedConstraints[focusArea] = constraint
                    }
                }
                
                return claim - unclaimed
            }
        }
        
        /// Claims vespene from unused resources
        /// Reclaims from open budgets to shift priorities if needed
        func claimVespene(_ claim: Int) -> Int {
            if assignableVespene >= claim {
                assignableVespene -= claim
                return claim
            } else {
                var unclaimed = claim - assignableMinerals
                assignableMinerals = 0
                
                for (focusArea, result) in results where result.type == .deprioritize && unclaimed > 0 {
                    if var constraint = assignedConstraints[focusArea] {
                        if constraint.budget.vespene >= unclaimed {
                            constraint.budget.vespene -= unclaimed
                            unclaimed = 0
                            return claim
                        } else {
                            unclaimed -= constraint.budget.vespene
                            constraint.budget.vespene = 0
                        }
                        
                        assignedConstraints[focusArea] = constraint
                    }
                }
                
                return claim - unclaimed
            }
        }
        
        let priorityRequests = results.filter { $0.value.type == .prioritize }.compactMap { area, value -> (FocusArea, StrategyContinuationRecommendation, Float)? in
            guard let priority = recommendations.first(where: { $0.area == area })?.weight else {
                return nil
            }
            
            return (area, value, priority)
        }.sorted { lhs, rhs in
            lhs.2 > rhs.2
        }
        
        nextFocusArea: for (focusArea, recommendation, priority) in priorityRequests {
            guard maxAssignableMinerals() > 0 || maxAssignableVespene() > 0 else {
                return
            }
            
            guard var constraints = assignedConstraints[focusArea] else {
                assertionFailure()
                continue nextFocusArea
            }
            
            if let minimumRequestedBudget = recommendation.minimumRequestedBudget {
                // No maximum, so we try to give the exact amount
                constraints.budget.minerals += claimMinerals(minimumRequestedBudget.minerals)
                constraints.budget.vespene += claimVespene(minimumRequestedBudget.vespene)
            } else {
                // In order to allow a critical strategy to consume all strategy, such as for defense
                // This allows escalating the priority by to maximum 150%
                // This way an urgent request can prevent being blocked by lower priority tasks
                let escalatedPriority = priority * 1.5
                let maxMineralBudget = min(maxAssignableMinerals(), Int(Float(maxAssignableMinerals()) * escalatedPriority))
                let maxVespeneBudget = min(maxAssignableVespene(), Int(Float(maxAssignableVespene()) * escalatedPriority))
                
                // Give percentage based on priority remainder stake
                var allocatedMinerals = maxMineralBudget
                var allocatedVespene = maxVespeneBudget
                
                if let maximumRequestedBudget = recommendation.maximumRequestedBudget {
                    // Give percentage based on priority remainder stake UP TO this budget
                    allocatedMinerals = min(allocatedMinerals, maximumRequestedBudget.minerals)
                    allocatedVespene = min(allocatedVespene, maximumRequestedBudget.vespene)
                }
                
                // Allocate all acknowledged budget
                constraints.budget.minerals += claimMinerals(allocatedMinerals)
                constraints.budget.vespene += claimVespene(allocatedVespene)
            }
            
            assignedConstraints[focusArea] = constraints
        }
    }
}

let localMap = "/Users/joannisorlandos/Projects/cpp-sc2/maps/Ladder/(2)Bel'ShirVestigeLE (Void).SC2Map"
let blizzardMap = "Lava Flow"
let game = SC2Game()

do {
    try game.startGame(
        onMap: .localPath(localMap),
    //    onMap: .battlenet(blizzardMap),
        realtime: false,
        players: [
            .standardAI(SC2AIPlayer(race: .terran, difficulty: .easy)),
            .participant(.zerg, .bot(CustomBot.self))
        ]
    ).wait()
} catch {
    try game.quit().wait()
    throw error
}
