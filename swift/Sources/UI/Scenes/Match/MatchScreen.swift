import Foundation
import SwiftGodot
import NetworkModels

@Godot
final class MatchScreen: Node {

	@Export
	var mapContainer: SubViewport!

	@Export
	var playerListView: MatchPlayerListView!

	@Export
	var btnEndTurn: Button!

	private var players: [MatchPlayer] = []
	private var mapView: MapView!

	private var currentPlayerId: String!

	private var ws: WebSocketClient!
	private var binaryMessageHandler: Callable?

	override func _ready() {
		setupSubViewport()
	}

	func initialize(settings: NMMatchSettings, players: [NMMatchPlayer], startingPlayer: String, mapData: NMMatchMapData, ws: WebSocketClient) {
		for i in 0..<players.count {
			self.players.append(MatchPlayer(index: i, nmMatchPlayer: players[i]))
		}
		//TODO: map setup
		
		currentPlayerId = startingPlayer
		playerListView.add(players: self.players, currentPlayerId: currentPlayerId)

		binaryMessageHandler = ws.dataReceived.connect(handleBinaryMessage)
		ws.getParent()?.removeChild(node: ws)
		addChild(node: ws)
		self.ws = ws
		
		createMapView(mapData: mapData)
	}

	private func setupSubViewport() {
		// Enable local input processing for mouse events
		mapContainer.handleInputLocally = true
		
		// Enable physics object picking for Area2D mouse detection
		mapContainer.physicsObjectPicking = true
	}

	private func createMapView(mapData: NMMatchMapData) {
		if let mapView = SceneLoader.load(path: "res://Screens/Match/map_view.tscn") as? MapView {
			self.mapView = mapView
			mapView.set(mapData: mapData)
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
				case let msg as NMMatchPlayerLeft:
					//remove(playerId: msg.playerId)
					break;
				case let msg as NMMatchTurnEnded:
					//TODO: 
					break;
				case let msg as NMMatchNewTurnStarted:
					newTurnStarted(newPlayerId: msg.playerId)
				default:
					GD.print("Received unsupported binary message type \(message)")
			}
		} catch {
			GD.print("Failed to decode binary message: \(error)")
			GD.print(error.localizedDescription)
		}
	}

	private func newTurnStarted(newPlayerId: String) {
		currentPlayerId = newPlayerId
		playerListView.updateCurrentPlayer(id: currentPlayerId)
	}
}

