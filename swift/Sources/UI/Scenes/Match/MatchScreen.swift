import Foundation
import NetworkModels
import SwiftGodot

@Godot
final class MatchScreen: Node {

	@Export
	var mapContainer: SubViewport!

	@Export
	var viewBattle: MatchBattleView!

	@Export
	var viewTurnTimer: MatchTurnTimerView!

	@Export
	var playerListView: MatchPlayerListView!

	@Export
	var btnEndTurn: Button!

	private var mapView: MapView!

	private var match: Match!

	private var ws: WebSocketClient!

	override func _ready() {
		setupSubViewport()
		createMapView()

		playerListView.add(
			players: match.players, currentPlayerId: match.currentPlayer.id, user: match.user)

		ws.getParent()?.removeChild(node: ws)
		addChild(node: ws)

		viewBattle.hide()
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
	}

	private func setupSubViewport() {
		// Enable local input processing for mouse events
		mapContainer.handleInputLocally = true

		// Enable physics object picking for Area2D mouse detection
		mapContainer.physicsObjectPicking = true
	}

	private func createMapView() {
		if let mapView = SceneLoader.load(path: "res://Screens/Match/map_view.tscn") as? MapView {
			self.mapView = mapView
			mapView.set(match: match)
			mapContainer.addChild(node: mapView)
		} else {
			//TODO: handle error in more restrictive way, something is very wrong, kick user out?
			GD.print("Failed to load map view")
			ErrorManager.showError(message: "Failed to load map view")
		}
	}

	private func handle(error: MatchIncosistencyError) {
		//TODO: show popup and disconnect player?
	}

	@Callable
	func endTurnPressed() {
		do {
			let endTurnMsg = NMMatchEndTurn()
			let data = try NMEncoder.encode(endTurnMsg)
			try ws.send(data: data)
		} catch {
			//TODO: add error handling
			GD.print("Failed to send message NMMatchEndTurn")
		}
	}

}
