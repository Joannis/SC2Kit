import Foundation
import SC2Kit

extension Array where Element == Larva {
    mutating func makeSupply(spawningOverlords: Int, gamestate: inout GamestateHelper) {
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
    
    mutating func trainDrones(_ drones: Int, gamestate: inout GamestateHelper) {
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

final class CustomBot: BotPlayer, BotPlayerHelpers {
    init() {}
    
    func expand() {
        // Return if it's not safe now
        // Return if we have no idle workers
        
        // Expand if we have Idle workers
        // Expand if we're floating too many minerals
    }
    
    func runTick(gamestate: inout GamestateHelper) {
        var larva = gamestate.units.only(Larva.self)
        let eggs = gamestate.units.only(Egg.self)
        let spawningOverlords = eggs.spawning(into: .overlord).count
        let spawningDrones = eggs.spawning(into: .overlord).count
        
        let mineralClusters = gamestate.units.minerals.formClusters()
        print(mineralClusters.count, " total known clusters")
        
        for cluster in mineralClusters {
            print("Cluster remaining minerals", cluster.remainingMinerals)
        }
        
        larva.makeSupply(spawningOverlords: spawningOverlords, gamestate: &gamestate)
        
        let surplusDrones = gamestate.units.only(Hatchery.self).reduce(0, { $0 + $1.harvesterSurplus }) - spawningDrones
        // Train drones until we're at max 70
        // Balance vespene & minerals
        larva.trainDrones(-surplusDrones, gamestate: &gamestate)
    }
}

let localMap = "/Users/joannisorlandos/Projects/cpp-sc2/maps/Ladder/(2)Bel'ShirVestigeLE (Void).SC2Map"
let blizzardMap = "Lava Flow"
let game = SC2Game()

do {
    try game.startGame(
        onMap: .localPath(localMap),
    //    onMap: .battlenet(blizzardMap),
        realtime: true,
        players: [
            .standardAI(SC2AIPlayer(race: .terran, difficulty: .easy)),
            .participant(.zerg, .bot(CustomBot.self))
        ]
    ).wait()

    let futures = game.bots.map { $0.startStepping() }

    for future in futures {
        try future.wait()
    }
} catch {
    try game.quit().wait()
    throw error
}
// TODO: Create game
// TODO: Join game
