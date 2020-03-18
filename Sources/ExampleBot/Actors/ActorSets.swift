import SC2Kit

enum StandardActorSet: ActorSet {
    static func makeDefensiveActor() -> some StrategyActor {
        SupplyStrategyActor() // TODO:
    }
    
    static func makeOffensiveActor() -> some StrategyActor {
        ZergMilitaryTechnologist()
    }
    
    static func makeScoutActor() -> some StrategyActor {
        SupplyStrategyActor() // TODO:
    }
    
    static func makeSupplyActor() -> some StrategyActor {
        SupplyStrategyActor()
    }
    
    static func makeEconomyActor() -> some StrategyActor {
        EconomyCompoundStrategyActor()
    }
}
