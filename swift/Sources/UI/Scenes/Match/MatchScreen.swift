import Foundation
import NetworkModels
import SwiftGodot

extension MatchScreen: SceneLoadable {
	static var pathToScene: String {
		"res://Screens/Match/match_screen.tscn"
	}
}

@Godot
final class MatchScreen: Node {

	@Export
	var mapContainer: SubViewport!

	@Export
	var lblReinforcementDice: Label!

	@Export
	var btnEndTurn: Button!

	@Export
	var btnQuit: Button!

	@Export
	var btnSurrender: Button!

	@Export
	var colorRect: ColorRect!

	@Export(.nodeType)
	var viewBattle: MatchBattleView!
	@Export(.nodeType)
	var viewTurnTimer: MatchTurnTimerView!
	@Export(.nodeType)
	var playerListView: MatchPlayerListView!

	@Export(.nodeType)
	var reinforcementsAutoDistributor: MatchReinforcementsAutoDistributor!
	@Export(.nodeType)
	var reinforcementsManualDistributor: MatchReinforcementsManualDistributor!

	private var mapView: MapView!

	private var match: Match!

	private var ws: WebSocketClient!

	override func _ready() {

		setupSubViewport()
		createMapView()

		playerListView.add(
			players: match.players, currentPlayerId: match.currentPlayer.id, user: match.user, match: match)

		ws.getParent()?.removeChild(node: ws)
		addChild(node: ws)

		viewBattle.hide()
		lblReinforcementDice.hide()

	}

	func initialize(
		user: User,
		settings: NMMatchSettings, players: [NMMatchPlayer], startingPlayer: String,
		mapData: NMMatchMapData, ws: WebSocketClient
	) {
		let matchPlayers = players.map { MatchPlayer(nmMatchPlayer: $0) }

		do {
			try match = Match(
				mapData: mapData,
				players: matchPlayers,
				user: user, currentPlayerId: startingPlayer,
				settings: settings,
				matchScreen: self,
				ws: ws)
		} catch {
			handle(error: error)
		}

		self.ws = ws

		reinforcementsManualDistributor.initialize(map: match.map)
		reinforcementsAutoDistributor.initialize(map: match.map)

		if startingPlayer == user.player.id {
			btnEndTurn.show()
		} else {
			btnEndTurn.hide()
		}

		btnSurrender.show()
		btnQuit.hide()

		if let mePlayer = matchPlayers.first(where: { $0.id == user.player.id }) {
			colorRect.color = mePlayer.color
		}
	}

	private func setupSubViewport() {
		// Enable local input processing for mouse events
		mapContainer.handleInputLocally = true

		// Enable physics object picking for Area2D mouse detection
		mapContainer.physicsObjectPicking = true
	}

	private func createMapView() {
		self.mapView = MapView.loadScene()
		mapView.set(match: match)
		mapContainer.addChild(node: mapView)
	}

	private func handle(error: MatchIncosistencyError) {
		//TODO: show popup and disconnect player?
	}

	@Callable
	func endTurnPressed() {
		match.endTurn()
	}

	@Callable
	func quitPressed() {
		ConfirmationPopup.show(on: getTree()?.currentScene, text: "Are you sure you want to quit the game?", confirmText: "Quit") { [unowned self] in
			//TODO: send some goodbye/cleanup message. It might be useful to know player initiated disconnect

			self.quitGame()
		}
	}

	@Callable
	func surrenderPressed() {
		ConfirmationPopup.show(on: getTree()?.currentScene, text: "Are you sure you want to surrender?", confirmText: "Surrender") { [unowned self] in
			do {
				try self.ws.send(message: NMMatchSurrender())
			} catch {
				//TODO: add error handling
				GD.print("Failed to send message NMMatchSurrender")
			}
		}
		btnSurrender.disabled = true
	}

	private func quitGame() {
		ws.close()

		let lobby = MainLobby.loadScene()
		lobby.initialize(user: match.user)
		changeSceneToNode(node: lobby)
	}

	func playerDisconnected(playerId: String) {
		playerListView.playerDisconnected(playerId: playerId)
	}

	func playerReconnected(playerId: String) {
		playerListView.playerReconnected(playerId: playerId)
	}

	func updateCurrentPlayer(id: String, amICurrent: Bool) {
		playerListView.updateCurrentPlayer(id: id)
		if amICurrent {
			btnEndTurn.show()
		} else {
			btnEndTurn.hide()
		}
	}

	func updateStrengths(_ strengts: [NMMatchPlayerStrength]) {
		for s in strengts {
			playerListView.update(strength: Int(s.strength), playerIndex: Int(s.playerIndex))
		}
	}

	func updateAttackBoost(count: Int, playerId: String) {
		playerListView.updateAttackBoost(count: count, playerId: playerId)
	}

	func updateDefenceBoost(count: Int, playerId: String) {
		playerListView.updateDefenceBoost(count: count, playerId: playerId)
	}

	func playerEliminated(_ player: MatchPlayer, result: MatchEliminationResult) {

		playerKicked(playerId: player.id)

		//show him as eliminated in player list

		if player.id == match.user.player.id {
			showDefeatPopup(result: result)
		}
	}

	func playerKicked(playerId: String) {
		match.map.regions.filter { $0.owner?.id == playerId }.forEach { $0.markAsDefeated() }
		playerListView.playerWasDefeated(playerId: playerId)
	}

	private func showDefeatPopup(result: MatchEliminationResult) {
		let popup = PlayerEliminatedPopup.loadScene()
		popup.initialize(result: result)
		popup.onQuitCallback = quitGame
		addChild(node: popup)

		btnSurrender.hide()
		btnQuit.show()
	}

	func gameOver() {
		viewTurnTimer.stop()
		playerListView.updateCurrentPlayer(id: "")
		btnEndTurn.hide()

		btnSurrender.hide()
		btnQuit.show()
	}
}
