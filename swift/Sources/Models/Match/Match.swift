import Foundation
import NetworkModels
import SwiftGodot

enum MatchIncosistencyError: Error {
	case playerNotFound
	case regionNotFound
}

private struct PendingState {
	let state: MatchState
	let timestamp: Date
}

class Match {
	let map: Map
	//let regions: [MatchRegion]
	let players: [MatchPlayer]

	private var state: MatchState = .intro
	{
		didSet {
			GD.print("state: \(state)")
		}
	}

	private var pendingState: PendingState?

	var currentPlayer: MatchPlayer
	var user: User
	private let ws: WebSocketClient
	private unowned let matchScreen: MatchScreen

	private var binaryMessageHandler: Callable?

	init(
		mapData: NMMatchMapData, players: [MatchPlayer], user: User, currentPlayerId: String,
		matchScreen: MatchScreen, ws: WebSocketClient
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
		self.matchScreen = matchScreen

		if currentPlayer.id == user.player.id {
			state = .myTurn(.attackerSelection)
		} else {
			state = .enemyTurn(.idle)
		}

		binaryMessageHandler = ws.dataReceived.connect(handleBinaryMessage)

		matchScreen.viewTurnTimer.startTurn()
	}

	private func handleBinaryMessage(data: PackedByteArray) {
		do {
			let message = try NMDecoder.decode(data.asBytes())
			GD.print("MatchScreen message received: \(message)")
			switch message {
				/*case let msg as NMMatchPlayerLeft:
					//remove(playerId: msg.playerId)
					break
				case let msg as NMMatchTurnEnded:
					//TODO:
					break*/
				case let msg as NMMatchEndTurn:
					//just a placeholder, nothing is needed to be done for now, since we are reacting to new turn
					break
				case let msg as NMMatchNewTurnStarted:
					newTurnStarted(newPlayerId: msg.playerId)
				case let msg as NMMatchBattleResults:
					handleBattleResults(msg: msg)
				case let msg as NMMatchReinforcementsResults:
					handleAutomaticReinforcements(msg: msg)
				case let msg as NMMatchStartManualReinforcements:
					handleManualReinforcements(msg: msg)
				case let msg as NMMatchManualReinforcementPlacementConfirmed:
					handleManualReinforcementsConfirmation(msg: msg)
				default:
					GD.print("Received unsupported binary message type \(message)")
			}
		} catch {
			GD.print("Failed to decode binary message: \(error)")
			GD.print(error.localizedDescription)
		}
	}

	private func handle(error: MatchIncosistencyError) {
		//TODO: show popup and disconnect player?
	}

	private func newTurnStarted(newPlayerId: String) {
		do {
			try newTurnStarted(newCurrentPlayerId: newPlayerId)
		} catch {
			handle(error: error)
		}
		matchScreen.playerListView.updateCurrentPlayer(id: currentPlayer.id)
		matchScreen.viewTurnTimer.startTurn()
	}

	private func handleBattleResults(msg: NMMatchBattleResults) {
		startBattle(using: msg)
		matchScreen.viewBattle.start(battle: msg.battle)
	}

	private func handleAutomaticReinforcements(msg: NMMatchReinforcementsResults) {
		matchScreen.viewTurnTimer.stop()
		// This can happen if timer runs in manual distribution mode and we still have some reinforcements
		matchScreen.reinforcementsManualDistributor.stopDistribution()
		matchScreen.reinforcementsAutoDistributor.startDistribution(results: msg.results)
	}

	private func handleManualReinforcements(msg: NMMatchStartManualReinforcements) {
		matchScreen.viewTurnTimer.startReinforcements(count: Int(msg.reinforcementsCount))
		startManualReinforcements(playerId: msg.playerId, dice: Int(msg.reinforcementsCount))
	}
}

// State management
extension Match {

	func onRegionClicked(regionId: Int) {
		let region = map.region(id: regionId)

		if region.owner?.id == user.player.id {
			myRegionClicked(region)
		} else {
			enemyRegionClicked(region)
		}
	}

	func endTurn() {
		if case .myTurn(let turnState) = state {
			switch turnState {
				case .attackerSelection:
					do {
						let endTurnMsg = NMMatchEndTurn()
						try ws.send(message: endTurnMsg)
					} catch {
						//TODO: add error handling
						GD.print("Failed to send message NMMatchEndTurn")
					}
				case .reinforcementSelection(_):
					do {
						let endReinforcementsMsg = NMMatchEndReinforcements()
						try ws.send(message: endReinforcementsMsg)
					} catch {
						//TODO: add error handling
						GD.print("Failed to send message NMMatchEndReinforcements")
					}

				default:
					break
			}
		}
	}

	func startManualReinforcements(playerId: String, dice: Int) {
		if case .enemyTurn(let turnState) = state {
			switch turnState {
				case .idle:
					state = .enemyTurn(.reinforcementSelection)
				case .combatInProgress:
					pendingState = PendingState(
						state: .enemyTurn(.reinforcementSelection),
						timestamp: .now)
				case .reinforcementSelection:
					GD.print("duplicate manual reinforcementSelection message received")
					break
			}
		} else if case .myTurn(let turnState) = state {
			switch turnState {
				case .attackerSelection:
					state = .myTurn(.reinforcementSelection(dice))
					matchScreen.reinforcementsManualDistributor.startDistribution(dice: dice, sendReinforcements: sendManualReinforcements)
				case .combatInitiated(let sourceRegion, let targetRegion):
					sourceRegion.regionView.isSelected = false
					targetRegion.regionView.isSelected = false
					state = .myTurn(.reinforcementSelection(dice))
					matchScreen.reinforcementsManualDistributor.startDistribution(dice: dice, sendReinforcements: sendManualReinforcements)
				case .targetSelection(let sourceRegion):
					sourceRegion.regionView.isSelected = false
				case .combatInProgress:
					pendingState = PendingState(
						state: .myTurn(.reinforcementSelection(dice)),
						timestamp: .now)
				case .reinforcementSelection:
					GD.print("duplicate manual reinforcementSelection message received")
					break
			}
		}
	}

	private func sendManualReinforcements(_ reinforcements: [Int: Int]) {
		do {
			let reinfs = reinforcements.keys.map { NMMatchReinforcementsResult(regionId: UInt8($0), dice: UInt8(reinforcements[$0]!)) }
			let reinfMsg = NMMatchManualReinforcementPlaced(reinforcements: reinfs)
			try ws.send(message: reinfMsg)
		} catch {
			//TODO: add error handling
			GD.print("Failed to send message NMMatchManualReinforcementPlaced")
		}
	}

	private func handleManualReinforcementsConfirmation(msg: NMMatchManualReinforcementPlacementConfirmed) {
		if case .enemyTurn(let turnState) = state {
			switch turnState {
				case .reinforcementSelection:
					matchScreen.reinforcementsAutoDistributor.startDistribution(results: msg.reinforcements)
				default:
					GD.print("ERROR: Received NMMatchManualReinforcementPlacementConfirmed messaga while in \(state)")
			}
		} else if case .myTurn(let turnState) = state {
			switch turnState {
				case .reinforcementSelection:
					matchScreen.reinforcementsManualDistributor.confirm(reinforcements: msg.reinforcements)
				default:
					GD.print("ERROR: Received NMMatchManualReinforcementPlacementConfirmed messaga while in \(state)")
			}
		}
	}

	func newTurnStarted(newCurrentPlayerId: String) throws(MatchIncosistencyError) {
		guard let newCurrentPlayer = players.first(where: { $0.id == newCurrentPlayerId }) else {
			throw .playerNotFound
		}
		currentPlayer = newCurrentPlayer

		matchScreen.lblReinforcementDice.hide()

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
				case .reinforcementSelection(_):
					matchScreen.reinforcementsManualDistributor.regionSelected(region: region)
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
					//Task {
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
				//}

				default:
					break
			}
		}
	}

	func startBattle(using msg: NMMatchBattleResults) {

		switch state {
			case .enemyTurn(let turnState):
				if turnState == .idle {
					let attackerRegion = map.region(id: Int(msg.attackerRegionId))
					let defenderRegion = map.region(id: Int(msg.defenderRegionId))
					attackerRegion.regionView.isSelected = true
					defenderRegion.regionView.isSelected = true
				}
			case .myTurn(let turnState):
				switch turnState {
					case .combatInitiated(_, _):
						state = .myTurn(.combatInProgress)
						break
					default:
						break
				}
			default:
				break
		}

		matchScreen.viewTurnTimer.pause()
		Task {
			try? await Task.sleep(for: .milliseconds(Timings.battleDuration * msg.battle.battleThrows.count))
			Callable({ _ in

				switch self.state {
					case .myTurn(let turnState):
						switch turnState {
							case .combatInProgress:
								self.state = .myTurn(.attackerSelection)
							default:
								break
						}
					default:
						break
				}

				self.applyBattleResults(msg: msg)
				self.matchScreen.viewBattle.close()

				self.matchScreen.viewTurnTimer.unpause()

				return nil
			})
			.callDeferred()
		}
	}

	private func applyBattleResults(msg: NMMatchBattleResults) {
		let attackerRegion = map.region(id: Int(msg.attackerRegionId))
		let defenderRegion = map.region(id: Int(msg.defenderRegionId))
		attackerRegion.dice = Int(msg.newAttackerDice)
		defenderRegion.dice = Int(msg.newDefenderDice)
		let newOwner = players[Int(msg.newDefenderOwnerIndex)]
		defenderRegion.owner = newOwner
		defenderRegion.regionView.set(owner: newOwner)
		defenderRegion.updateBorders(map: map, owner: newOwner)

		attackerRegion.regionView.isSelected = false
		defenderRegion.regionView.isSelected = false
	}
}

enum MatchState {
	case intro
	case myTurn(MyTurnState)
	case enemyTurn(EnemyTurnState)
	case gameOver
}

enum MyTurnState {
	case attackerSelection
	case targetSelection(MatchRegion)
	case combatInitiated(MatchRegion, MatchRegion)
	case combatInProgress
	case reinforcementSelection(Int)
}

enum EnemyTurnState {
	case idle
	case combatInProgress
	case reinforcementSelection
}
