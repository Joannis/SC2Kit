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
                    if case .participant(_, .bot(let botType)) = player.setup {
                        let bot = SC2Bot(configuration: config, bot: botType.init(), client: player.client)
                        self.bots.append(bot)
                    }
                    
                    return joinPlayer(i + 1)
                }
            }
            
            return joinPlayer(0)
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
    
    fileprivate init(configuration: PlayerConfiguration, bot: BotPlayer, client: SC2Client) {
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
    
    public func tick() -> EventLoopFuture<Void> {
        return observe().map(bot.onStep).map { _ in }
    }
    
    public func startStepping() -> EventLoopFuture<Void> {
        assert(client.status == .inGame)
        
        guard !stepping else {
            fatalError("Cannot start stepping a bot more than once")
        }
        
        stepping = true
        
        func nextTick() -> EventLoopFuture<Void> {
            self.tick().flatMap {
                nextTick()
            }
        }
        
        return nextTick()
    }
}

struct Closed: Error {}

public final class SC2Client {
    private let websocket: WebSocket
    private var promise: EventLoopPromise<ByteBuffer>?
    public let port: Int
    internal private(set) var status: SC2APIProtocol_Status = .launched
    
    private init(websocket: WebSocket, port: Int) {
        self.websocket = websocket
        self.port = port
        
        websocket.onBinary { [unowned self] _, data in
            self.receiveData(data)
        }
        
        websocket.onClose.whenSuccess { [unowned self] in
            self.promise?.fail(Closed())
        }
    }
    
    func receiveData(_ data: ByteBuffer) {
        promise?.succeed(data)
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
    
    internal func send<Output: SwiftProtobuf.Message>(_ input: inout SC2APIProtocol_Request, outputKeyPath: KeyPath<SC2APIProtocol_Response, Output>) -> EventLoopFuture<Output> {
        if websocket.isClosed {
            return self.websocket.eventLoop.makeFailedFuture(Closed())
        }
        
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
    
    func joinPlayer(_ player: SC2Player) -> EventLoopFuture<PlayerConfiguration> {
        assert(status == .initGame || status == .launched)
        var join = SC2APIProtocol_RequestJoinGame()
        
        join.options.raw = true
        join.options.score = true
        join.options.showCloaked = true
        join.options.showBurrowedShadows = true
        join.participation = player.participation
        
        var request = SC2APIProtocol_Request()
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
        return send(&request, outputKeyPath: \.action).map { response in }
    }
}

extension SC2APIProtocol_ResponseCreateGame.Error: Error {}
extension SC2APIProtocol_ResponseJoinGame.Error: Error {}
struct SC2Errors: Error {
    let errors: [String]
}

public protocol BotPlayer {
    init()
    
    func onStep(observing observation: Observation) -> [Action]
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
    case commandUnit(Ability, Target)
    
    var sc2: SC2APIProtocol_Action {
        var action = SC2APIProtocol_Action()
        
        switch self {
        case .commandUnit(let ability, let target):
            action.actionRaw.unitCommand.abilityID = ability.id
            action.actionRaw.unitCommand.target = target.sc2
        }
        
        return action
    }
}

public enum Target {
    case none
    case unit(UnitTag)
    case position(x: Float, y: Float)
    
    var sc2: SC2APIProtocol_ActionRawUnitCommand.OneOf_Target? {
        switch self {
        case .none:
            return nil
        case .unit(let tag):
            return .targetUnitTag(tag.tag)
        case .position(let x, let y):
            var point = SC2APIProtocol_Point2D()
            point.x = x
            point.y = y
            return .targetWorldSpacePos(point)
        }
    }
}

public struct UnitTag {
    let tag: UInt64
}

public enum Ability {
    var id: Int32 {
        return 0
    }
}
