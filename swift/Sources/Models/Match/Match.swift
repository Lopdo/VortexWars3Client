import Foundation
import NetworkModels
import SwiftGodot

enum MatchIncosistencyError: Error {
	case playerNotFound
	case regionNotFound
}

class Match {
	let map: Map
	//let regions: [MatchRegion]
	let players: [MatchPlayer]

	private var state: MatchState = .intro
	var currentPlayer: MatchPlayer
	var user: User
	private var ws: WebSocketClient

	init(
		mapData: NMMatchMapData, players: [MatchPlayer], user: User, currentPlayerId: String,
		ws: WebSocketClient
	)
		throws(MatchIncosistencyError)
	{
		guard let currentPlayer = players.first(where: { $0.id == currentPlayerId }) else {
			throw .playerNotFound
		}

		map = Map(mapData: mapData, players: players)

		self.players = players
		self.user = user
		self.currentPlayer = currentPlayer
		self.ws = ws

		if currentPlayer.id == user.player.id {
			state = .myTurn(.attackerSelection)
		} else {
			state = .enemyTurn(.idle)
		}
	}

}

// State management
extension Match {

	func onRegionClicked(regionId: Int) {
		let region = map.regions[regionId - 1]

		if region.owner?.id == user.player.id {
			myRegionClicked(region)
		} else {
			enemyRegionClicked(region)
		}
	}

	func placeReinforcements() {
		// cleanup selections and other stuff
		if case .myTurn(let turnState) = state {
			switch turnState {
			case .targetSelection(let sourceRegion):
				sourceRegion.regionView.isSelected = false
			case .combatInitiated(let sourceRegion, let targetRegion):
				sourceRegion.regionView.isSelected = false
				targetRegion.regionView.isSelected = false
			default:
				break
			}
		}

		state = .reinforcements
	}

	func newTurnStarted(newCurrentPlayerId: String) throws(MatchIncosistencyError) {
		guard let newCurrentPlayer = players.first(where: { $0.id == newCurrentPlayerId }) else {
			throw .playerNotFound
		}
		currentPlayer = newCurrentPlayer

		// update state
		if currentPlayer.id == user.player.id {
			state = .myTurn(.attackerSelection)
		} else {
			state = .enemyTurn(.idle)
		}
	}

	private func myRegionClicked(_ region: MatchRegion) {
		if case .myTurn(let turnState) = state {
			switch turnState {
			case .attackerSelection:
				region.regionView.isSelected = true
				state = .myTurn(.targetSelection(region))
			case .targetSelection(let oldRegion):
				oldRegion.regionView.isSelected = false
				region.regionView.isSelected = true
				state = .myTurn(.targetSelection(region))
			case .reinforcementSelection:
				//TODO:
				break
			default:
				break
			}
		}
	}

	private func enemyRegionClicked(_ region: MatchRegion) {
		if case .myTurn(let turnState) = state {
			switch turnState {
			case .targetSelection(let sourceRegion):
				region.regionView.isSelected = true
				Task {
					do {
						let battleMsg = NMMatchBattleInitiated(
							attackerRegionId: UInt8(sourceRegion.id),
							targetRegionId: UInt8(region.id))
						try ws.send(message: battleMsg)
						state = .myTurn(.combatInitiated(sourceRegion, region))
					} catch {
						//TODO: add error handling
						GD.print("Failed to send message NMMatchEndTurn")
						region.regionView.isSelected = false
					}
				}

			default:
				break
			}
		}
	}

	func applyBattleResults(msg: NMMatchBattleResults) {
		let attackerRegion = map.regions[Int(msg.attackerRegionId) - 1]
		let defenderRegion = map.regions[Int(msg.defenderRegionId) - 1]
		attackerRegion.armySize = Int(msg.newAttackerDice)
		defenderRegion.armySize = Int(msg.newDefenderDice)
		let newOwner = players[Int(msg.newDefenderOwnerIndex)]
		defenderRegion.owner = newOwner
		defenderRegion.regionView.set(owner: newOwner)
		defenderRegion.updateBorders(map: map, owner: newOwner)

		switch state {
		case .enemyTurn(let turnState):
			if turnState == .idle {
				attackerRegion.regionView.isSelected = true
				defenderRegion.regionView.isSelected = true
			}
		case .myTurn(let turnState):
			switch turnState {
			case .combatInitiated(_, _):
				break
			default:
				break
			}
		default:
			break
		}

		Task {

			try? await Task.sleep(for: .seconds(2))
			Callable({ _ in
				attackerRegion.regionView.isSelected = false
				defenderRegion.regionView.isSelected = false
				return nil
			})
			.callDeferred()
		}
	}
}

enum MatchState {
	case intro
	case myTurn(MyTurnState)
	case reinforcements
	case enemyTurn(EnemyTurnState)
	case gameOver
}

enum MyTurnState {
	case attackerSelection
	case targetSelection(MatchRegion)
	case combatInitiated(MatchRegion, MatchRegion)
	case combatInProgress
	case reinforcementSelection
}

enum EnemyTurnState {
	case idle
	case combatInProgress
}
