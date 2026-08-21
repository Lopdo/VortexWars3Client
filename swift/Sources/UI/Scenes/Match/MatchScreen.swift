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
		//TODO: send some goodbye/cleanup message. It might be useful to know player initiated disconnect

		ws.close()

		let lobby = MainLobby.loadScene()
		lobby.initialize(user: match.user)
		changeSceneToNode(node: lobby)
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

	func showDefeatPopup(position: Int, gameOver: Bool) {
		let popup = PlayerEliminatedPopup.loadScene()
		popup.initialize(position: position, gameOver: gameOver)
		popup.onQuitCallback = quitPressed
		addChild(node: popup)
	}

	func gameOver() {
		viewTurnTimer.stop()
		playerListView.updateCurrentPlayer(id: "")
		btnEndTurn.hide()
	}
}
