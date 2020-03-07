import Foundation
import SC2Kit

final class CustomBot: BotPlayer, BotPlayerHelpers {
    init() {}
    
    func runTick(gamestate: inout GamestateHelper) {
        print(gamestate.units.only(Drone.self).count)
        print(gamestate.economy.minerals)
//        if gamestate.canAfford(Drone.self) {
//
//        }
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