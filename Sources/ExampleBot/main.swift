import Foundation
import SC2Kit

extension Array where Element == SC2Unit<Larva> {
    mutating func makeSupply(spawningOverlords: Int, gamestate: GamestateHelper) {
        let freeSupply = gamestate.economy.freeSupply + (spawningOverlords * 8)
        if freeSupply <= 2 {
            var neededSupply = gamestate.economy.supplyCap / 50
            
            if gamestate.economy.supplyCap % 50 > 0 {
                neededSupply += 1
            }
            
            var copy = self
            var i = self.count - 1
            trainLarva: while i > 0 {
                let larva = self[i]
                if neededSupply == 0 {
                    break trainLarva
                }
                
                if !larva.trainOverlord() {
                    break trainLarva
                }

                copy.remove(at: i)
                i -= 1
                neededSupply -= 1
            }
            self = copy
        }
    }
    
    mutating func trainDrones(_ drones: Int, gamestate: GamestateHelper) {
        var drones = drones

        var copy = self
        var i = self.count - 1
        trainLarva: while i > 0 {
            let larva = self[i]
            if drones == 0 {
                break trainLarva
            }
            
            if !larva.trainDrone() {
                break trainLarva
            }
            
            copy.remove(at: i)
            i -= 1
            drones -= 1
        }
        self = copy
    }
}

final class CustomBot: BotPlayer {
    func saveReplay(_ data: Data) {}
    var debugCommands = [DebugCommand]()
    var expanding: Position.World2D?
    var tick: UInt = 0
    
    func getClusters(gamestate: GamestateHelper) -> [(MineralCluster, Position.World)] {
        gamestate.units.resources.formClusters().compactMap { cluster -> (MineralCluster, Position.World)? in
            return (cluster, cluster.approximateExpansionLocation)
        }
    }
    
    func getClustersWithExpansion(gamestate: GamestateHelper) -> [(MineralCluster, Position.World, SC2Unit<Hatchery>)] {
        let hatcheries = gamestate.units.owned.only(Hatchery.self)
        return getClusters(gamestate: gamestate).compactMap { cluster, position in
            for hatchery in hatcheries {
                let isNearCluster = hatchery.worldPosition.as2D.distanceXY(to: position.as2D) <= 15
                
                if isNearCluster {
                    return (cluster, position, hatchery)
                }
            }
            
            return nil
        }
    }
    
    init() {}
    
    func setupDebug(gamestate: GamestateHelper) {
        if !debugCommands.isEmpty {
            return
        }
        
        #if DEBUG
        nextCluster: for (cluster, expansionPosition) in getClusters(gamestate: gamestate) {
            debugCommands.append(.draw([
                .sphere(.init(at: cluster.approximateExpansionLocation, range: 3, color: .red)),
                .sphere(.init(at: expansionPosition, range: 5, color: .red)),
            ]))
            
            debugCommands.append(.draw(cluster.resources.map { resource in
                let distance = resource.worldPosition.as2D.distanceXY(to: expansionPosition.as2D)
                return .text(DebugString(text: "\(distance)", color: .white, position: .world(resource.worldPosition)))
            }))
        }
        #endif
    }
    
    func expand(usingDrones drones: inout [SC2Unit<Drone>], nearExpansions currentExpansions: [SC2Unit<Hatchery>], gamestate: GamestateHelper) {
        let isExpanding = drones.contains { drone in
            drone.orders.contains { $0.ability == .buildHatchery }
        }
        
        guard
            !isExpanding,
            gamestate.canAfford(Hatchery.self),
            !drones.isEmpty
        else {
            return
        }
        
        // Detect current expansions and ignore those clusters
        let allClusters = getClusters(gamestate: gamestate)
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
            drone.buildHatchery(at: position.as2D)
        }
        
        // Choose base closest to our current expansions
        
        // Return if it's not safe now
        // Return if we have no idle workers
        
        // Expand if we have Idle workers
        // Expand if we're floating too many minerals
    }
    
    func debug() -> [DebugCommand] {
        return debugCommands
    }
    
    func balanceEconomy(gamestate: GamestateHelper) {
        let expansions = self.getClustersWithExpansion(gamestate: gamestate)
        var drones = gamestate.units.owned.only(Drone.self)
        self.expand(usingDrones: &drones, nearExpansions: expansions.map { $0.2 }, gamestate: gamestate)
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
        
        nextExpansion: for (cluster, _, hatchery) in expansions where !idleDrones.isEmpty {
            if hatchery.harvesterSurplus < 0 {
                let neededHarvesters = -hatchery.harvesterSurplus
                
                for _ in 0..<neededHarvesters where !idleDrones.isEmpty {
                    guard let mineral = cluster.resources.minerals.randomElement() else {
                        continue nextExpansion
                    }
                    
                    let assignedDrone = idleDrones.removeFirst()
                    assignedDrone.harvest(mineral)
                }
                // TODO: Prefer nearby idle drones over far away idle drones
                // But CPU performance? Let's check that, too
                
                // Drones needed
            }
        }
        
//        for drone in idleDrones {
            // Use these drones!
//        }
    }
    
    func runTick(gamestate: GamestateHelper) {
        tick = tick &+ 1
        
        setupDebug(gamestate: gamestate)
        
        if tick % 50 == 0 {
            balanceEconomy(gamestate: gamestate)
        }
        
        var larva = gamestate.units.owned.only(Larva.self)
        let eggs = gamestate.units.owned.only(Egg.self)
        let spawningDrones = eggs.spawning(into: .drone).count
        let spawningOverlords = eggs.spawning(into: .overlord).count
        
        larva.makeSupply(spawningOverlords: spawningOverlords, gamestate: gamestate)
        
        if gamestate.economy.usedWorkerSupply < 70 {
            let surplusDrones = gamestate.units.owned.only(Hatchery.self).reduce(0, { $0 + $1.harvesterSurplus }) - spawningDrones
            // TODO: Balance vespene & minerals
            larva.trainDrones(-surplusDrones, gamestate: gamestate)
        }
        
        // TODO: Vespene
        // TODO: ARMY!
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
// TODO: Create game
// TODO: Join game
