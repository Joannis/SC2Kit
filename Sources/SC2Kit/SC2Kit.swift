import SwiftProtobuf
import Darwin
import Foundation
import NIO
import WebSocketKit

public final class SC2Game {
    private var players = [(client: SC2Client, setup: SC2Player)]()
    public private(set) var bots = [SC2Bot]()
    let group: MultiThreadedEventLoopGroup
    let loop: EventLoop
    
    public init() {
        group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        loop = group.next()
    }
    
    public func quit() -> EventLoopFuture<Void> {
        var request = SC2APIProtocol_Request()
        request.quit = .init()
        
        let done = players.map { player in
            player.client.send(&request, outputKeyPath: \.quit).map { _ in }
        }
        
        return EventLoopFuture.andAllSucceed(done, on: loop)
    }
    
    public func startGame(
        onMap map: SC2Map,
        realtime: Bool,
        saveReplay: Bool = true,
        players: [SC2Player]
    ) -> EventLoopFuture<Void> {
        if players.isEmpty {
            fatalError("Cannot create an empty game")
        }
        
        let basePort = Int.random(in: 5000..<6000)
        var done = [EventLoopFuture<Void>]()
        
        for i in 0..<players.count {
            if case .participant = players[i] {
                done.append(
                    SC2Client.launch(group: group, port: basePort + i).map { client in
                        self.players.append((client, players[i]))
                    }
                )
            }
        }
        
        return EventLoopFuture.andAllSucceed(done, on: loop).flatMap {
            return self.players[0].client.createGame(onMap: map, realtime: realtime, players: players)
        }.flatMap {
            func joinPlayer(_ i: Int) -> EventLoopFuture<Void> {
                if i >= self.players.count {
                    return self.loop.makeSucceededFuture(())
                }
                
                let player = self.players[i]
                
                return player.client.joinPlayer(player.setup).flatMap { config in
                    return player.client.getGameInfo().flatMap { gameInfo in
                        if case .participant(_, .bot(let botType)) = player.setup {
                            let bot = SC2Bot(
                                configuration: config,
                                bot: botType.init(),
                                client: player.client,
                                gameInfo: gameInfo
                            )
                            self.bots.append(bot)
                        }
                        
                        return joinPlayer(i + 1)
                    }
                }
            }
            
            return joinPlayer(0)
        }.flatMap {
            let done = self.bots.map { $0.startStepping(realtime: realtime) }
            
            return EventLoopFuture.andAllComplete(done, on: self.loop)
        }
    }
    
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

public final class SC2Bot {
    public let configuration: PlayerConfiguration
    private var stepping = false
    fileprivate let bot: BotPlayer
    private let client: SC2Client
    private let gamestate: GamestateHelper
    
    fileprivate init(configuration: PlayerConfiguration, bot: BotPlayer, client: SC2Client, gameInfo: GameInfo) {
        self.gamestate = GamestateHelper(
            observation: .init(response: .init()),
            gameInfo: gameInfo
        )
        self.configuration = configuration
        self.bot = bot
        self.client = client
    }
    
    internal func observe() -> EventLoopFuture<Observation> {
        assert(client.status == .inGame)
        var request = SC2APIProtocol_Request()
        request.observation = .init()
        
        return client.send(&request, outputKeyPath: \.observation).map(Observation.init)
    }
    
    func sendActions(_ actions: [Action]) -> EventLoopFuture<Void> {
        if actions.isEmpty {
            return self.client.eventLoop.makeSucceededFuture(())
        } else {
            return client.sendActions(actions)
        }
    }
    
    func tick(placedBuildings: [PlaceBuilding]) -> EventLoopFuture<[PlaceBuilding]> {
        return observe().flatMap { observation in
            self.gamestate.observation = observation
            self.gamestate.actions.removeAll(keepingCapacity: true)
            self.gamestate.placedBuildings.removeAll(keepingCapacity: true)
            
            for building in placedBuildings {
                building.onSuccess(self.gamestate)
            }
            
            self.bot.runTick(gamestate: self.gamestate)
            return self.paintDebugCommands(self.bot.debug()).flatMap {
                self.sendActions(self.gamestate.actions)
            }.map {
                self.gamestate.placedBuildings
            }
        }
    }
    
    public func canPlaceBuilding(
        _ placedBuilding: PlaceBuilding
    ) -> EventLoopFuture<Bool> {
        var request = SC2APIProtocol_Request()
        var placement = SC2APIProtocol_RequestQueryBuildingPlacement()
        placement.abilityID = placedBuilding.ability.rawValue
        placement.placingUnitTag = placedBuilding.unit.tag
        placement.targetPos = placedBuilding.position.sc2
        request.query.placements = [placement]
        request.query.ignoreResourceRequirements = placedBuilding.ignoreResourceRequirements
        
        return client.send(&request, outputKeyPath: \.query).flatMapThrowing { response in
            guard response.placements.count == 1 else {
                throw InvalidResponse()
            }
            
            return PlacementResponse(response: response.placements[0]).success
        }
    }
    
    public func paintDebugCommands(_ commands: [DebugCommand]) -> EventLoopFuture<Void> {
        if commands.isEmpty {
            return self.client.eventLoop.makeSucceededFuture(())
        }
        
        var request = SC2APIProtocol_Request()
        request.debug.debug = commands.map { $0.sc2 }
        
        return client.send(&request, outputKeyPath: \.debug).map { _ in }
    }
    
    func startStepping(realtime: Bool) -> EventLoopFuture<Void> {
        assert(client.status == .inGame)
        
        guard !stepping else {
            fatalError("Cannot start stepping a bot more than once")
        }
        
        
        stepping = true
        
        func nextTick(placedBuildings: [PlaceBuilding]) -> EventLoopFuture<Void> {
            if self.gamestate.willQuit {
                var request = SC2APIProtocol_Request()
                request.quit = .init()
                return client.send(&request, outputKeyPath: \.quit).flatMap { _ in
                    if !self.bot.saveReplay {
                        return self.client.eventLoop.makeSucceededFuture(())
                    }
                    
                    var request = SC2APIProtocol_Request()
                    request.saveReplay = .init()
                    return self.client.send(&request, outputKeyPath: \.saveReplay).map { replay in
                        self.bot.saveReplay(replay.data)
                    }
                }
            }
            
            return self.tick(placedBuildings: placedBuildings).flatMap { newPlacedBuildings in
                if realtime {
                    return nextTick(placedBuildings: newPlacedBuildings)
                } else {
                    var request = SC2APIProtocol_Request()
                    assert(self.bot.loopsPerTick > 0, "Cannot increment by less than 1 step")
                    request.step.count = UInt32(self.bot.loopsPerTick)
                    return self.client.send(&request, outputKeyPath: \.step).flatMap { _ in
                        nextTick(placedBuildings: newPlacedBuildings)
                    }
                }
            }
        }
        
        return nextTick(placedBuildings: [])
    }
}

public final class SC2Client {
    private let websocket: WebSocket
    public var eventLoop: EventLoop { websocket.eventLoop }
    private var promises = [UInt32: EventLoopPromise<SC2APIProtocol_Response>]()
    public let port: Int
    private var id: UInt32 = 0
    internal private(set) var status: SC2APIProtocol_Status = .launched
    
    private init(websocket: WebSocket, port: Int) {
        self.websocket = websocket
        self.port = port
        
        websocket.onBinary { [unowned self] _, data in
            self.receiveData(data)
        }
        
        websocket.onClose.whenSuccess { [unowned self] in
            for promise in self.promises.values {
                promise.fail(Closed())
            }
        }
    }
    
    func receiveData(_ data: ByteBuffer) {
        do {
            let data = data.getData(at: 0, length: data.readableBytes)!
            let response = try SC2APIProtocol_Response(serializedData: data)
            promises[response.id]?.succeed(response)
        } catch {
            print(error)
        }
    }
    
    static func connect(group: EventLoopGroup, port: Int) -> EventLoopFuture<SC2Client> {
        let promise = group.next().makePromise(of: SC2Client.self)
        
        let configuration = WebSocketClient.Configuration(maxFrameSize: 16_000_000)
        WebSocket.connect(to: "ws://127.0.0.1:\(port)/sc2api", configuration: configuration, on: group) { websocket in
            promise.succeed(SC2Client(websocket: websocket, port: port))
        }.cascadeFailure(to: promise)
        
        return promise.futureResult
    }
    
    static func launch(group: EventLoopGroup, port: Int, timeout: Int = 30) -> EventLoopFuture<SC2Client> {
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
        
        return retry(timeout)
    }
    
    internal func send<Output>(_ input: inout SC2APIProtocol_Request, outputKeyPath: KeyPath<SC2APIProtocol_Response, Output>) -> EventLoopFuture<Output> {
        if websocket.isClosed {
            return self.websocket.eventLoop.makeFailedFuture(Closed())
        }
        
        do {
            input.id = self.id
            self.id = self.id &+ 1
            
            try websocket.send(raw: input.serializedData(), opcode: .binary)
        } catch {
            return websocket.eventLoop.makeFailedFuture(error)
        }
        
        let promise = websocket.eventLoop.makePromise(of: SC2APIProtocol_Response.self)
        self.promises[input.id] = promise
        
        return promise.futureResult.flatMapThrowing { response -> Output in
            if !response.error.isEmpty {
                throw SC2Errors(errors: response.error)
            }
            
            self.status = response.status
            
            return response[keyPath: outputKeyPath]
        }
    }
    
    func createGame(
        onMap map: SC2Map,
        realtime: Bool,
        players: [SC2Player]
    ) -> EventLoopFuture<Void> {
        assert(status == .launched)
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
        
        return send(&request, outputKeyPath: \.createGame).flatMapThrowing { response in
            if response.hasError {
                throw response.error
            }
        }
    }
    
    func getGameInfo() -> EventLoopFuture<GameInfo> {
        var request = SC2APIProtocol_Request()
        request.gameInfo = .init()
        
        return self.send(&request, outputKeyPath: \.gameInfo).map(GameInfo.init)
    }
    
    func joinPlayer(_ player: SC2Player) -> EventLoopFuture<PlayerConfiguration> {
        assert(status == .initGame || status == .launched)
        var request = SC2APIProtocol_Request()
        var join = SC2APIProtocol_RequestJoinGame()
        
        join.options.raw = true
        join.options.score = true
        join.options.showCloaked = true
        join.options.showBurrowedShadows = true
        join.participation = player.participation
        
        request.joinGame = join
        
        return self.send(&request, outputKeyPath: \.joinGame).flatMapThrowing { response in
            if response.hasError {
                throw response.error
            }
            
            return PlayerConfiguration(playerId: Int(response.playerID))
        }
    }
    
    func sendActions(_ actions: [Action]) -> EventLoopFuture<Void> {
        var request = SC2APIProtocol_Request()
        request.action.actions = actions.map { $0.sc2 }
        return send(&request, outputKeyPath: \.action).map { _ in }
    }
}

extension SC2APIProtocol_ResponseCreateGame.Error: Error {}
extension SC2APIProtocol_ResponseJoinGame.Error: Error {}
struct Closed: Error {}
struct InvalidResponse: Error {}
struct SC2Errors: Error {
    let errors: [String]
}

extension BotPlayer {
    public func debug() -> [DebugCommand] { [] }
}

public struct PlayerConfiguration {
    public let playerId: Int
}

public struct Observation {
    let observation: SC2APIProtocol_Observation
    
    init(response: SC2APIProtocol_ResponseObservation) {
        self.observation = response.observation
    }
    
    public var player: ObservedPlayer {
        ObservedPlayer(player: observation.playerCommon)
    }
}

public struct ObservedPlayer {
    let player: SC2APIProtocol_PlayerCommon
    
    public var minerals: Int {
        Int(player.minerals)
    }
    
    public var vespene: Int {
        Int(player.vespene)
    }
    
    public var usedSupply: Int {
        Int(player.foodUsed)
    }
    
    public var usedArmySupply: Int {
        Int(player.foodArmy)
    }
    
    public var usedWorkerSupply: Int {
        Int(player.foodWorkers)
    }
    
    public var supplyCap: Int {
        Int(player.foodCap)
    }
    
    public var freeSupply: Int {
        supplyCap - usedSupply
    }
    
    public var larvaCount: Int {
        Int(player.larvaCount)
    }
    
    public var warpgateCount: Int {
        Int(player.warpGateCount)
    }
}

public enum Action {
    case commandUnits([UnitTag], Ability, Target)
    
    var sc2: SC2APIProtocol_Action {
        var action = SC2APIProtocol_Action()
        
        switch self {
        case .commandUnits(let tags, let ability, let target):
            action.actionRaw.unitCommand.abilityID = ability.rawValue
            action.actionRaw.unitCommand.unitTags = tags.map { $0.tag }
            action.actionRaw.unitCommand.target = target.sc2
            action.actionRaw.unitCommand.queueCommand = true
        }
        
        return action
    }
}

public enum Target {
    case none
    case unit(UnitTag)
    case position(Position.World2D)
    
    var sc2: SC2APIProtocol_ActionRawUnitCommand.OneOf_Target? {
        switch self {
        case .none:
            return nil
        case .unit(let tag):
            return .targetUnitTag(tag.tag)
        case .position(let position):
            return .targetWorldSpacePos(position.sc2)
        }
    }
}

public struct UnitTag {
    let tag: UInt64
}

public enum Ability: Int32 {
    case trainDrone = 1342
    case trainZergling = 1343
    case trainOverlord = 1344
    case droneGather = 1183
    case buildHatchery = 1152
    case move = 3794
    
    var trainedUnit: UnitType? {
        switch self {
        case .trainDrone:
            return .drone
        case .trainZergling:
            return .zergling
        case .trainOverlord:
            return .overlord
        default:
            return nil
        }
    }
}

public struct PlacementResponse {
    let response: SC2APIProtocol_ResponseQueryBuildingPlacement
    
    public var success: Bool {
        response.result == .success
    }
}
