public enum SC2Map {
    case battlenet(String)
    case localPath(String)
}

public enum Player {
    case human
    case bot(BotPlayer.Type)
}

public enum SC2Player {
    case standardAI(SC2AIPlayer)
    case observer
    case participant(Race, Player)
    
    var participation: SC2APIProtocol_RequestJoinGame.OneOf_Participation {
        switch self {
        case .standardAI(let sc2ai):
            return .race(sc2ai.race.sc2)
        case .participant(let race, _):
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
        case .participant(let race, _):
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
