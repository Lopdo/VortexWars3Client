extension Match {
	func stateChanged(from oldState: MatchState, to newState: MatchState) {
		switch oldState {
			case .myTurn(let turnState):
				switch turnState {
					case .targetSelection(let region):
						if case .myTurn(let newTurnState) = newState,
							case .combatInitiated = newTurnState
						{
							// Do not clean up the selected region, we need it for battle
						} else {
							region.regionView.isSelected = false
						}
					case .reinforcementSelection(_):
						matchScreen.lblReinforcementDice.hide()
						matchScreen.reinforcementsAutoDistributor.finishDistribution()
						matchScreen.reinforcementsManualDistributor.stopDistribution()
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
