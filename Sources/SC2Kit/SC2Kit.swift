import SwiftProtobuf
import Darwin
import Foundation
import NIO
import WebSocketKit

final class SC2Game {
    static func launch(port: Int) {
        let sc2 = Process()
        sc2.launchPath = "/Applications/StarCraft II/Versions/Base78285/SC2.app/Contents/MacOS/SC2"
        sc2.arguments = [
            "-listen", "127.0.0.1",
            "-port", String(port),
            "-displaymode", "0", // 1 is fullscreen, 0 is windowed
            //            "-dataVersion \(SC2APIProtocol_ResponseReplayInfo)",
            //            -windowwidth
            //            -windowheight
            //            -windowx
            //            -windowy
        ]
        sc2.launch()
    }
}

public final class SC2Client {
    private let websocket: WebSocket
    private var promise: EventLoopPromise<ByteBuffer>?
    
    private init(websocket: WebSocket) {
        self.websocket = websocket
        
        websocket.onBinary { [unowned self] _, data in
            self.receiveData(data)
        }
        
        websocket.onClose.whenSuccess { [unowned self] in
            struct Closed: Error {}
            self.promise?.fail(Closed())
        }
    }
    
    func receiveData(_ data: ByteBuffer) {
        promise?.succeed(data)
    }
    
    public static func connect(group: EventLoopGroup, port: Int) -> EventLoopFuture<SC2Client> {
        let promise = group.next().makePromise(of: SC2Client.self)
        
        WebSocket.connect(to: "ws://127.0.0.1:\(port)/sc2api", on: group) { websocket in
            promise.succeed(SC2Client(websocket: websocket))
        }.cascadeFailure(to: promise)
        
        return promise.futureResult
    }
    
    public static func launch() -> EventLoopFuture<SC2Client> {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let port = 5679
        SC2Game.launch(port: port)
        
        func retry(_ n: Int) -> EventLoopFuture<SC2Client> {
            if n == 0 {
                return connect(group: group, port: port)
            } else {
                return connect(group: group, port: port).flatMapError { _ in
                    sleep(1)
                    return retry(n - 1)
                }
            }
        }
        
        return retry(10)
    }
    
    internal func send<Input: SwiftProtobuf.Message, Output: SwiftProtobuf.Message>(_ input: Input, outputKeyPath: KeyPath<SC2APIProtocol_Response, Output>) -> EventLoopFuture<Output> {
        // TODO: Support pipelining
        assert(promise == nil)
        
        do {
            try websocket.send(raw: input.serializedData(), opcode: .binary)
        } catch {
            return websocket.eventLoop.makeFailedFuture(error)
        }
        
        let promise = websocket.eventLoop.makePromise(of: ByteBuffer.self)
        self.promise = promise
        
        return promise.futureResult.flatMapThrowing { buffer -> Output in
            self.promise = nil
            let data = buffer.getData(at: 0, length: buffer.readableBytes)!
            let response = try SC2APIProtocol_Response(serializedData: data)
            return response[keyPath: outputKeyPath]
        }
    }
    
    public func startGame(onMap map: SC2Map, realtime: Bool, players: [SC2Player]) -> EventLoopFuture<Void> {
        var create = SC2APIProtocol_RequestCreateGame()
        
        switch map {
        case .battlenet(let map):
            create.map = .battlenetMapName(map)
        case .localPath(let path):
            var localMap = SC2APIProtocol_LocalMap()
            localMap.mapPath = path
            create.localMap = localMap
        }
        
        for player in players {
            create.playerSetup.append(player.sc2)
        }
        
        create.realtime = realtime
        
        var request = SC2APIProtocol_Request()
        request.createGame = create
        
        return send(request, outputKeyPath: \.createGame).flatMap { response in
            if response.hasError {
                print(response.errorDetails)
                return self.websocket.eventLoop.makeFailedFuture(response.error)
            }

            func joinPlayer(_ i: Int) -> EventLoopFuture<Void> {
                if i >= players.count {
                    return self.websocket.eventLoop.makeSucceededFuture(())
                }

                var join = SC2APIProtocol_RequestJoinGame()

                join.options.raw = true
                join.options.score = true
                join.options.showCloaked = true
                join.options.showBurrowedShadows = true
                join.participation = players[i].participation

                var request = SC2APIProtocol_Request()
                request.joinGame = join

                return self.send(request, outputKeyPath: \.joinGame).flatMap { response in
                    if response.hasError {
                        print(response.errorDetails)
                        return self.websocket.eventLoop.makeFailedFuture(response.error)
                    }

                    return joinPlayer(i + 1)
                }
            }

            return joinPlayer(0)
        }
    }
}

extension SC2APIProtocol_ResponseCreateGame.Error: Error {}
extension SC2APIProtocol_ResponseJoinGame.Error: Error {}

public enum SC2Map {
    case battlenet(String)
    case localPath(String)
}

public enum Player {
    case human
    case bot(BotPlayer)
}

public protocol BotPlayer: class {
    
}

public enum SC2Player {
    case standardAI(SC2AIPlayer)
    case observer
    case participant(Race, Player)
    
    var participation: SC2APIProtocol_RequestJoinGame.OneOf_Participation {
        switch self {
        case .standardAI(let sc2ai):
            return .race(sc2ai.race.sc2)
        case .participant(let race):
            return .race(race.sc2)
        case .observer:
            return .observedPlayerID(0)
        }
    }
    
    var sc2: SC2APIProtocol_PlayerSetup {
        var setup = SC2APIProtocol_PlayerSetup()
        
        switch self {
        case .standardAI(let sc2ai):
            setup.difficulty = sc2ai.difficulty.sc2
            setup.type = .computer
            setup.race = sc2ai.race.sc2
            setup.aiBuild = .macro
        case .observer:
            setup.type = .observer
        case .participant(let race):
            setup.type = .participant
            setup.race = race.sc2
        }
        
        return setup
    }
}

public struct SC2AIPlayer {
    public var race: Race
    public var difficulty: Difficulty
    // TODO: Build
    
    public init(race: Race, difficulty: Difficulty) {
        self.race = race
        self.difficulty = difficulty
    }
}

public enum Race {
    case zerg, protoss, terran, random
    
    var sc2: SC2APIProtocol_Race {
        switch self {
        case .protoss:
            return .protoss
        case .zerg:
            return .zerg
        case .terran:
            return .terran
        case .random:
            return .random
        }
    }
}

public enum Difficulty {
    case veryEasy // = 1
    case easy // = 2
    case medium // = 3
    case mediumHard // = 4
    case hard // = 5
    case harder // = 6
    case veryHard // = 7
    case cheatVision // = 8
    case cheatMoney // = 9
    case cheatInsane // = 10
    
    var sc2: SC2APIProtocol_Difficulty {
        switch self {
        case .veryEasy:
            return .veryEasy
        case .easy:
            return .easy
        case .medium:
            return .medium
        case .mediumHard:
            return .mediumHard
        case .hard:
            return .hard
        case .harder:
            return .harder
        case .veryHard:
            return .veryHard
        case .cheatVision:
            return .cheatVision
        case .cheatMoney:
            return .cheatMoney
        case .cheatInsane:
            return .cheatInsane
        }
    }
}
