import Foundation
import SwiftGodot
import NetworkModels

@Godot
final class MatchesSectionView: Control {
	
	private let client = WebSocketClient()
	private var binaryMsgHandlerToken: Callable?

	var user: User!

	@Export
	var createMatchButton: Button!
	@Export
	var matchList: VBoxContainer!

	@Export
	var loadingIndicator: CanvasItem!

	override func _ready() {
		addChild(node: client)
		
		client.connectedToServer.connect(connectedToServer)
		client.connectionClosed.connect {
			GD.print("Client just disconnected with code: \(self.client.socket.getCloseCode()), reason: \(self.client.socket.getCloseReason())")
		}

		loadingIndicator.hide()

		onRefresh()
	}

	@Callable
	func onCreateMatchButtonPressed() {
		GD.print("Create Match button pressed")
		
		connectToWebSocket()
	}

	@Callable
	func onRefresh() {
		let matchViews = matchList.getChildren()
		for mv in matchViews {
			matchList.removeChild(node: mv)
		}

		loadingIndicator.show()

		NetworkManager.jsonRequest(
			node: self,
			url: "/match/list",
			method: .get,
			completion: requestCompleted
		)
	}

	private func requestCompleted(result: Result<MatchListDTO, Error>) {
		loadingIndicator.hide()

		switch result {
			case .success(let matchListDTO):
				for match in matchListDTO.matches {
					createMatchView(for: match)
				}
			case .failure(let error):
				GD.print("An error occurred in the HTTP request: \(error)")
				ErrorManager.showError(message: "An error occurred in the HTTP request. \(error.localizedDescription)")
		}
	}

	private func createMatchView(for match: MatchDTO) {
		if let matchView = SceneLoader.load(path: "res://Screens/MainLobby/match_view.tscn") as? MatchView {
			matchView.setup(with: match)
			matchList.addChild(node: matchView)
			matchView.pressed.connect {
				self.joinTapped(match: match)
			}
		}
	}

	private func joinTapped(match: MatchDTO) {
		binaryMsgHandlerToken = client.dataReceived.connect(handleJoinBinaryMessage)

		let host = "127.0.0.1:8080/match/join?id=\(match.id.string)"
		GD.print("Connecting to host: \(host)")
		let err = client.connectTo(url: "ws://\(host)")
		if err != .ok {	
			GD.print("Error connecting to host: \(err)")
		}
	}
	
	private func connectToWebSocket() {
		binaryMsgHandlerToken = client.dataReceived.connect(handleCreateBinaryMessage)
		
		let host = "127.0.0.1:8080/match/create"
		GD.print("Connecting to host: \(host)")
		let err = client.connectTo(url: "ws://\(host)")
		if err != .ok {	
			GD.print("Error connecting to host: \(err)")
		}
	}

	private func connectedToServer() {
		GD.print("Client just connected with protocol: \(client.socket.getSelectedProtocol())")
		do {
			let auth = NMPlayerAuth(playerId: user.player.id, authToken: user.sessionToken)
			let data = try NMEncoder.encode(auth)
			try client.send(data: data)
		} catch {
			GD.print("Failed to encode NMPlayerAuth: \(error)")
		}
	}

	private func handleCreateBinaryMessage(data: PackedByteArray) {
		do {
			let message = try NMDecoder.decode(data.asBytes())
			GD.print("MatchesSectionView message received: \(message)")
			switch message {
				case let msg as NMPlayerAuthResult:
					if msg.success {
						createMatch()	
					} else {
						GD.print("Authentication failed: \(msg.message ?? "<Unknown error>")")
					}
				case let msg as NMMatchJoined:
					joinMatch(msg)
				default:
					GD.print("Received unknown binary message type")
			}
		} catch {
			GD.print("Failed to decode binary message: \(error)")
			GD.print(error.localizedDescription)
		}
	}

	private func handleJoinBinaryMessage(data: PackedByteArray) {
		do {
			let message = try NMDecoder.decode(data.asBytes())
			GD.print("MatchesSectionView message received: \(message)")
			switch message {
				case let msg as NMPlayerAuthResult:
					if msg.success {
						do {
							let data = try NMEncoder.encode(NMPlayerAuthAck())
								try client.send(data: data)
								GD.print("AuthAck message sent")
						} catch {
							GD.print("Failed to encode NMPlayerAuthAck: \(error)")
						}
					} else {
						GD.print("Authentication failed: \(msg.message ?? "<Unknown error>")")
					}
				case let msg as NMMatchJoined:
					joinMatch(msg)
				default:
					GD.print("Received unknown binary message type")
			}
		} catch {
			GD.print("Failed to decode binary message: \(error)")
			GD.print(error.localizedDescription)
		}
	}

	private func joinMatch(_ msg: NMMatchJoined) {
		GD.print("Joined match with ID: \(msg.id)")
			if let lobby = SceneLoader.load(path: "res://Screens/MatchLobby/match_lobby.tscn") as? MatchLobby {
				if let binaryMsgHandlerToken {
					client.dataReceived.disconnect(binaryMsgHandlerToken)
				}
				lobby.initialize(ws: client, user: user, players: msg.players)
					changeSceneToNode(node: lobby)
			}
	}

	private func createMatch() {
		let settings = NMMatchSettings(mapId: "123", gameName: "Test game name", maxPlayers: 4)
		let message = NMCreateMatch(settings: settings)
		do {
			let data = try NMEncoder.encode(message)
			try client.send(data: data)
			GD.print("Create match message sent, name: \(settings)")
		} catch {
			GD.print("Failed to encode NMCreateMatch: \(error)")
		}
	}
}
