extension Match {
	func stateChanged(from oldState: MatchState, to newState: MatchState) {
		switch oldState {
			case .myTurn(let turnState):
				switch turnState {
					case .targetSelection(let region):
						region.regionView.isSelected = false
					case .reinforcementSelection(_):
						matchScreen.lblReinforcementDice.hide()
						matchScreen.reinforcementsAutoDistributor.finishDistribution()
						matchScreen.reinforcementsManualDistributor.stopDistribution()
					case .combatInitiated(let sourceRegion, let targetRegion):
						sourceRegion.regionView.isSelected = false
						targetRegion.regionView.isSelected = false
					default:
						// nothing to clean up
						break
				}
			case .enemyTurn(let turnState):
				switch turnState {
					case .reinforcementSelection(_):
						matchScreen.reinforcementsAutoDistributor.finishDistribution()
					default:
						// nothing to clean up
						break
				}

			default:
				// nothing to clean up
				break
		}
	}
}

