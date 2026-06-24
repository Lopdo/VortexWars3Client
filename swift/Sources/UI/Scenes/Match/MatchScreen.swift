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
	var playerListView: MatchPlayerListView!

	@Export
	var btnEndTurn: Button!

	private var mapView: MapView!

	private var match: Match!

	private var ws: WebSocketClient!
	private var binaryMessageHandler: Callable?

	override func _ready() {
		setupSubViewport()
		createMapView()

		playerListView.add(
			players: match.players, currentPlayerId: match.currentPlayer.id, user: match.user)

		binaryMessageHandler = ws.dataReceived.connect(handleBinaryMessage)
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
				case let msg as NMMatchNewTurnStarted:
					newTurnStarted(newPlayerId: msg.playerId)
				case let msg as NMMatchBattleResults:
					handleBattleResults(msg: msg)
				default:
					GD.print("Received unsupported binary message type \(message)")
			}
		} catch {
			GD.print("Failed to decode binary message: \(error)")
			GD.print(error.localizedDescription)
		}
	}

	private func newTurnStarted(newPlayerId: String) {
		do {
			try match.newTurnStarted(newCurrentPlayerId: newPlayerId)
		} catch {
			handle(error: error)
		}
		playerListView.updateCurrentPlayer(id: match.currentPlayer.id)
	}

	private func handleBattleResults(msg: NMMatchBattleResults) {
		match.startBattle(using: msg)
		viewBattle.startBattle(battles: msg.battles)
	}

	private func handle(error: MatchIncosistencyError) {
		//TODO: show popup and disconnect player?
	}
}
