import Foundation
import SwiftGodot
import NetworkModels

@Godot
final class MatchesSectionView: Control {
	
	private let client = WebSocketClient()
	
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
		//client.textReceived.connect(handleMessage)
		client.dataReceived.connect(handleBinaryMessage)

		loadingIndicator.hide()
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

		let httpRequest = HTTPRequest()
		addChild(node: httpRequest)
		httpRequest.requestCompleted.connect { result, responseCode, headers, body in
			self.loadingIndicator.hide()
			self.httpRequestCompleted(result: result, responseCode: responseCode, headers: headers, body: body)
		}

		let error = httpRequest.request(url: "http://127.0.0.1:8080/match/list", method: .get)
		if error != .ok {
			loadingIndicator.hide()
			GD.print("An error occurred in the HTTP request.")
			ErrorManager.showError(message: "An error occurred in the HTTP request.")
		}
	}

	private func httpRequestCompleted(result: Int64, responseCode: Int64, headers: PackedStringArray, body: PackedByteArray) {
		if result != 0 {
			ErrorManager.showError(message: "An error occurred in the HTTP request. \(result)")
			return
		}

		GD.print("Response Body: \(body.getStringFromUtf8())")
		if responseCode == 500 {
			ErrorManager.showHTTPError(body: body)
		} else if responseCode == 200 {
			let data = Data(body.asBytes())
			do {
				let matchListDTO = try JSONDecoder().decode(MatchListDTO.self, from: data)
				for match in matchListDTO.matches {
					createMatchView(for: match)
				}
			} catch {
				ErrorManager.showError(message: "Failed to parse login response \(error)")
			}
		} else {
			ErrorManager.showError(message: "An error occurred in the HTTP request. \(responseCode)")
		}
	}

	private func createMatchView(for match: MatchDTO) {
		GD.print("create2")
		if let matchView = SceneLoader.load(path: "res://MainLobby/match_view.tscn") as? MatchView {
			matchView.setup(with: match)
			matchList.addChild(node: matchView)
			matchView.pressed.connect {
		GD.print("create")
				self.joinTapped(match: match)
			}
		}
	}

	private func joinTapped(match: MatchDTO) {
		let host = "127.0.0.1:8080/match/join?id=\(match.id.string)"
		GD.print("Connecting to host: \(host)")
		let err = client.connectTo(url: "ws://\(host)")
		if err != .ok {	
			GD.print("Error connecting to host: \(err)")
		}
	}
	
	private func connectToWebSocket() {
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
		//client.send(message: "\(user.player.id):\(user.sessionToken)")
		//addChatMessage(sender: "System", message: "Chat joined...")
	}

	private func handleBinaryMessage(data: PackedByteArray) {
		//GD.print("Received binary message of size: \(data.size())")

		do {
			let message = try NMDecoder.decode(data.asBytes())
			switch message {
				case let msg as NMPlayerAuthResult:
					if msg.success {
						createMatch()	
					} else {
						GD.print("Authentication failed: \(msg.message ?? "<Unknown error>")")
					}
				case let msg as NMMatchJoined:
					GD.print("Joined match with ID: \(msg.matchId)")
					
				default:
					GD.print("Received unknown binary message type")
			}
		} catch {
			GD.print("Failed to decode binary message: \(error)")
			GD.print(error.localizedDescription)
		}
	}

	private func createMatch() {
		let settings = NMMatchSettings(mapId: "123", gameName: "Test game name", maxPlayers: 4)
		let message = NMCreateMatch(settings: settings)
		do {
			let data = try NMEncoder.encode(message)
			try client.send(data: data)
		} catch {
			GD.print("Failed to encode NMCreateMatch: \(error)")
		}
	}
}
