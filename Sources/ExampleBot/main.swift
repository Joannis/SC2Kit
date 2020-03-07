import Foundation
import SC2Kit

let client = try SC2Client.launch().wait()
let localMap = "/Users/joannisorlandos/Projects/cpp-sc2/maps/Ladder/(2)Bel'ShirVestigeLE (Void).SC2Map"
let blizzardMap = "Lava Flow"
try client.startGame(
    onMap: .localPath(localMap),
//    onMap: .battlenet(blizzardMap),
    realtime: true,
    players: [
        .standardAI(SC2AIPlayer(race: .terran, difficulty: .easy)),
        .participant(.protoss)
    ]
).wait()

while true {
    sleep(100)
}

// TODO: Create game
// TODO: Join game
