import Foundation
import SwiftGodot
import NetworkModels

@Godot
final class MatchLobby: Node {

	@Export
	var playerList: VBoxContainer!

	@Export
	var buttonLeave: Button!

	@Export
	var buttonReady: Button!

	private var user: User!
	private var wsClient: WebSocketClient!

	private var isReady: Bool = false {
		didSet {
			buttonReady.text = isReady ? "Unready" : "Ready"
			updateReadyState(playerId: user.player.id, isReady: isReady)
		}
	}

	func initialize(ws: WebSocketClient, user: User, players: [NMMatchPlayer]) {
		wsClient = ws
		wsClient.dataReceived.connect(handleBinaryMessage)

		self.user = user

		for player in players {
			add(player: player)
		}
	}


	private func handleBinaryMessage(data: PackedByteArray) {
		do {
			let message = try NMDecoder.decode(data.asBytes())
			switch message {
				case let msg as NMMatchPlayerJoined:
					add(player: msg.player)
				case let msg as NMMatchPlayerLeft:
					remove(playerId: msg.playerId)
				case let msg as NMMatchPlayerReadyStatusChanged:
					updateReadyState(playerId: msg.playerId, isReady: msg.ready)
				default:
					GD.print("Received unknown binary message type")
			}
		} catch {
			GD.print("Failed to decode binary message: \(error)")
			GD.print(error.localizedDescription)
		}
	}

	private func add(player: NMMatchPlayer) {
		if let matchView = SceneLoader.load(path: "res://Screens/MatchLobby/match_lobby_player.tscn") as? MatchLobbyPlayerView {
			matchView.initialize(player: player)
			playerList.addChild(node: matchView)
		}
	}

	private func playerView(for playerId: String) -> MatchLobbyPlayerView? {
		let nodes = playerList.getChildren()
		if let playerView = nodes.first(where: { ($0 as? MatchLobbyPlayerView)?.player.id == playerId }) {
			return playerView as? MatchLobbyPlayerView
		} else {
			GD.print("PlayerView for \(playerId) not found")
			return nil
		}
	}

	private func remove(playerId: String) {
		playerList.removeChild(node: playerView(for: playerId))
	}

	private func updateReadyState(playerId: String, isReady: Bool) {
		if let playerView = playerView(for: playerId) {
			playerView.set(ready: isReady)
		}
	}

	@Callable
	func onChangeReady() {
		do {
			let auth = NMMatchPlayerChangeReadyStatus(ready: !isReady)
			let data = try NMEncoder.encode(auth)
			try wsClient.send(data: data)
			isReady.toggle()
		} catch {
			//TODO: add error handling
			GD.print("Failed to send message NMMatchPlayerChangeReadyStatus")
		}
	}

	@Callable
	func onExit() {
		wsClient.close()
		if let lobby = SceneLoader.load(path: "res://Screens/MainLobby/main_lobby.tscn") as? MainLobby {
			lobby.initialize(user: user)
				changeSceneToNode(node: lobby)
		} else {
			GD.print("Failed to load MainLobby scene")
				ErrorManager.showError(message: "Failed to load MainLobby scene")
		}
	}
}
