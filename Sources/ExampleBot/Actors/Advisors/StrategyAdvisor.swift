import SC2Kit

protocol StrategyAdvisor {
    func adviseStrategies(
        claimedBudget: Cost,
        gamestate: GamestateHelper
    ) -> [StrategyRecommendation]
}
