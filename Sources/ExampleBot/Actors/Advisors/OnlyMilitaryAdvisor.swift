import SC2Kit

struct OnlyMilitaryAdvisor: StrategyAdvisor {
    func adviseStrategies(
        claimedBudget: Cost,
        gamestate: GamestateHelper
    ) -> [StrategyRecommendation] {
        return [
            StrategyRecommendation(area: .attack, weight: 0.65),
            StrategyRecommendation(area: .expandSupply, weight: 0.25),
            StrategyRecommendation(area: .attack, weight: 0.1),
        ]
    }
}
