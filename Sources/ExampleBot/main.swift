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
    var debugCommands = [DebugCommand]()
    var clusters: [(MineralCluster, Position.World)]?
    var expanding: Position.World2D?
    var ticks = 0
    
    func getClusters(gamestate: GamestateHelper) -> [(MineralCluster, Position.World)] {
        if let clusters = self.clusters {
            return clusters
        }
        
        let mineralClusters = gamestate.units.minerals.formClusters().map { cluster in
            (cluster, cluster.approximateExpansionLocation)
        }
        
        self.clusters = mineralClusters
        return mineralClusters
    }
    
    init() {}
    
    func saveReplay(_ data: Data) {
        do {
            try data.write(to: URL(string: "file:///Users/joannisorlandos/Projects/SC2Kit/replay")!)
        } catch {
            print(error)
        }
    }
    
    func expand(gamestate: GamestateHelper) {
        // Detect current expansions and ignore those clusters
        let allClusters = getClusters(gamestate: gamestate)
        
        // TODO: Classify on occupation, not unscouted
        var possibleExpansions = allClusters.filter { $0.0.hasUnscoutedMinerals }
        
        for (cluster, expansionPosition) in allClusters {
            let centerOfMass = cluster.centerOfMass
            debugCommands.append(.draw([
                .sphere(.init(at: expansionPosition, range: 5, color: .blue)),
                .sphere(.init(at: centerOfMass, range: 1, color: .green)),
                .sphere(.init(at: cluster.closestMinerals(to: centerOfMass).worldPosition, range: 1, color: .red)),
                .text(DebugString(text: String(cluster.mineralPatches.count), color: .white, position: .world(centerOfMass)))
            ]))
            
            debugCommands.append(.draw(cluster.mineralPatches.map { mineral in
                let distance = mineral.worldPosition.as2D.distanceXY(to: centerOfMass.as2D)
                return .text(DebugString(text: "\(distance)", color: .white, position: .world(mineral.worldPosition)))
            }))
            
            debugCommands.append(.draw(cluster.mineralPatches.map { mineral in
                let distance = mineral.worldPosition.as2D.distanceXY(to: centerOfMass.as2D)
                return .sphere(.init(at: mineral.worldPosition, range: 0.5, color: .white))
            }))
        }
        
        let drones = gamestate.units.only(Drone.self)
        
        let isExpanding = drones.contains { $0.orders.contains { $0.ability == .buildHatchery } }
        
        guard
            !isExpanding,
            gamestate.canAfford(Hatchery.self),
            let drone = drones.randomElement()
        else {
            return
        }
        
        possibleExpansions.sort { lhs, rhs in
            let lhsDistance = lhs.1.as2D.distanceXY(to: drone.worldPosition.as2D)
            let rhsDistance = rhs.1.as2D.distanceXY(to: drone.worldPosition.as2D)
            
            return lhsDistance < rhsDistance
        }
        
        if let (_, position) = possibleExpansions.first {
            drone.buildHatchery(at: position.as2D)
            self.expanding = position.as2D
            // TODO: What if it cannot?
            print("expanding to \(position.x) \(position.y)")
        }
        
        // Choose base furthest from the enemy
        
        // Return if it's not safe now
        // Return if we have no idle workers
        
        // Expand if we have Idle workers
        // Expand if we're floating too many minerals
    }
    
    func debug() -> [DebugCommand] {
        return debugCommands
    }
    
    func runTick(gamestate: GamestateHelper) {
        // 22.4 ticks/second, rounded to 25
//        ticks += 1
//        if ticks > 25 * 300 {
//            gamestate.quit()
//        }
        debugCommands.removeAll(keepingCapacity: true)
        
        var larva = gamestate.units.only(Larva.self)
        let eggs = gamestate.units.only(Egg.self)
        let spawningOverlords = eggs.spawning(into: .overlord).count
        let spawningDrones = eggs.spawning(into: .overlord).count

        self.expand(gamestate: gamestate)
        
        larva.makeSupply(spawningOverlords: spawningOverlords, gamestate: gamestate)
        
        if gamestate.economy.usedWorkerSupply < 70 {
            let surplusDrones = gamestate.units.only(Hatchery.self).reduce(0, { $0 + $1.harvesterSurplus }) - spawningDrones
            // TODO: Balance vespene & minerals
            larva.trainDrones(-surplusDrones, gamestate: gamestate)
        }
        
        let spheres = gamestate.units.only(Drone.self).map { drone -> DebugDrawable in
            return .sphere(.init(at: drone.worldPosition, range: 1, color: .blue))
        }
        
        debugCommands.append(.draw(spheres))
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
