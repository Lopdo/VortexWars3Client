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

	@Export
	var buttonStart: Button!

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
		wsClient.getParent()?.removeChild(node: wsClient)
		addChild(node: wsClient)		

		self.user = user

		for player in players {
			add(player: player)
		}
		buttonStart.hide()
		buttonStart.disabled = true
		if players.first(where: { $0.id == user.player.id } )?.isCook == true {
			buttonStart.show()
		}
	}


	private func handleBinaryMessage(data: PackedByteArray) {
		do {
			let message = try NMDecoder.decode(data.asBytes())
			GD.print("MatchLobby message received: \(message)")
			switch message {
				case let msg as NMMatchPlayerJoined:
					add(player: msg.player)
				case let msg as NMMatchPlayerLeft:
					remove(playerId: msg.playerId)
				case let msg as NMMatchPlayerReadyStatusChanged:
					GD.print("NMMatchPlayerReadyStatusChanged received, playerId: \(msg.playerId), isReady: \(msg.ready)")
					updateReadyState(playerId: msg.playerId, isReady: msg.ready)
				case let msg as NMMatchStarted:
					GD.print("NMMatchStarted received")
				case let msg as NMMatchCookChanged:
					updateCook(newCookId: msg.playerId)
				case let msg as NMMatchAlreadyStarted:
					//TODO: show popup
					GD.print("Match already started")
				default:
					GD.print("Received unsupported binary message type \(message)")
			}
		} catch {
			GD.print("Failed to decode binary message: \(error)")
			GD.print(error.localizedDescription)
		}
	}

	private func add(player: NMMatchPlayer) {
		if let matchView = SceneLoader.load(path: "res://Screens/MatchLobby/match_lobby_player.tscn") as? MatchLobbyPlayerView {
			matchView.initialize(player: MatchPlayer(from: player))
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
		updateStartButton()
	}

	private func updateCook(newCookId: String) {
		if user.player.id == newCookId {
			buttonStart.show()
		} else {
			buttonStart.hide()
		}
		
		let playerViews = playerList.getChildren().compactMap { $0 as? MatchLobbyPlayerView }
		for pView in playerViews {
			pView.set(isCook: pView.player.id == newCookId)
		}
	}

	private func updateStartButton() {
		let playerViews = playerList.getChildren().compactMap { $0 as? MatchLobbyPlayerView }
		buttonStart.disabled = playerViews.contains(where: { !$0.player.isReady })
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

	@Callable
	func onStart() {
		do {
			let start = NMMatchStartRequested()
			let data = try NMEncoder.encode(start)
			try wsClient.send(data: data)
			buttonStart.disabled = true
		} catch {
			//TODO: add error handling
			GD.print("Failed to send message NMMatchPlayerChangeReadyStatus")
		}
	}
}
