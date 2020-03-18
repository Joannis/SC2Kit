import SC2Kit

struct OnlyEconomyAdvisor: StrategyAdvisor {
    func adviseStrategies(
        claimedBudget: Cost,
        gamestate: GamestateHelper
    ) -> [StrategyRecommendation] {
        return [
            StrategyRecommendation(area: .expandEconomy, weight: 0.7),
            StrategyRecommendation(area: .expandSupply, weight: 0.3)
        ]
    }
}
