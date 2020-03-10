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
    var clusters: [(MineralCluster, Position.World)]?
    var expanding: Position.World2D?
    var expansionCount = 1
    
    func getClusters(gamestate: GamestateHelper) -> [(MineralCluster, Position.World)] {
        if let clusters = self.clusters {
            return clusters
        }
        
        let mineralClusters = gamestate.units.resources.formClusters().compactMap { cluster -> (MineralCluster, Position.World)? in
//            guard let location = cluster.getExpansionLocation(in: gamestate) else {
//                return nil
//            }
            
            return (cluster, cluster.approximateExpansionLocation)
        }
        
        self.clusters = mineralClusters
        return mineralClusters
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
    
    func expand(gamestate: GamestateHelper) {
        // Detect current expansions and ignore those clusters
        let allClusters = getClusters(gamestate: gamestate)
        let currentExpansions = gamestate.units.only(Hatchery.self)
        
        if currentExpansions.count == expansionCount {
            expansionCount += 1
            self.expanding = nil
        }
        
        guard
            expanding == nil,
            gamestate.canAfford(Hatchery.self),
            let drone = gamestate.units.only(Drone.self).randomElement()
        else {
            return
        }
        
        var possibleExpansions = allClusters.filter { cluster in
            for expansion in currentExpansions {
                if expansion.worldPosition.as2D.distanceXY(to: cluster.1.as2D) <= 15 {
                    return false
                }
            }
            
            return true
        }
        
        possibleExpansions.sort { lhs, rhs in
            let lhsDistance = lhs.1.as2D.distanceXY(to: drone.worldPosition.as2D)
            let rhsDistance = rhs.1.as2D.distanceXY(to: drone.worldPosition.as2D)
            
            return lhsDistance < rhsDistance
        }
        
        if let (_, position) = possibleExpansions.first {
            drone.buildHatchery(at: position.as2D)
            self.expanding = position.as2D
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
        setupDebug(gamestate: gamestate)
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
