import Foundation
import SwiftGodot
import NetworkModels

@Godot
final class MainLobby: Node {
	private let client = WebSocketClient()

	@Export
	var lineEdit: LineEdit!
	@Export
	var chatContent: VBoxContainer!
	@Export
	var playerList: VBoxContainer!

	@Export
	var matchesSectionView: MatchesSectionView!

	private var user: User!
	
	override func _ready() {
		addChild(node: client)
		
		client.connectedToServer.connect(connectedToServer)
		client.connectionClosed.connect {
			GD.print("Client just disconnected with code: \(self.client.socket.getCloseCode()), reason: \(self.client.socket.getCloseReason())")
		}
		client.textReceived.connect(handleMessage)
		client.dataReceived.connect(handleBinaryMessage)

		matchesSectionView.user = user
	}
	
	func initialize(user: User) {
		self.user = user
		connectToWebSocket()
	}

	private func connectToWebSocket() {
		let host = "127.0.0.1:8080/chat/lobby"
		GD.print("Connecting to host: \(host)")
		let err = client.connectTo(url: "ws://\(host)")
		if err != .ok {	
			GD.print("Error connecting to host: \(err)")
		}
	}

	private func addChatMessage(sender: String, message: String) {
		let messageLabel = RichTextLabel()
		messageLabel.text = "[b]\(sender):[/b] \(escapeBBCode(bbcodeText: message))"
		messageLabel.fitContent = true
		messageLabel.bbcodeEnabled = true
		chatContent.addChild(node: messageLabel)
	}

	private func escapeBBCode(bbcodeText: String) -> String {
		// We only need to replace opening brackets to prevent tags from being parsed.
		return bbcodeText.replacingOccurrences(of: "[", with: "[lb]")
	}

	private func addPlayer(name: String, id: String) {
		let playerView = ChatMemberView()
		playerView.playerId = id
		playerView.text = name
		playerList.addChild(node: playerView)
	}

	private func removePlayer(id: String) {
		let nodes = playerList.getChildren()
		for n in nodes.compactMap({ $0 as? ChatMemberView }) {
			if n.playerId == id {
				playerList.removeChild(node: n)
			}
		}
	}
	
	private func initializeLobby(players: [NMLobbyMember]) {
		for player in players {
			addPlayer(name: player.playerName, id: player.playerId)
		}
	}

	@Callable
	func onSendPressed() {
		if lineEdit.text.isEmpty {
			return
		}

		GD.print("Sending message: \(lineEdit.text)")
		let err = client.send(message: lineEdit.text)
		if err != .ok {
			GD.print("Error sending message: \(err)")
		}
		lineEdit.text = ""
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

	private func handleBinaryMessage(data: PackedByteArray) {
		//GD.print("Received binary message of size: \(data.size())")

		do {
			let message = try NMDecoder.decode(data.asBytes())

			switch message {
				case let msg as NMPlayerAuthResult:
					if msg.success {
						GD.print("Authentication successful")
					} else {
						GD.print("Authentication failed: \(msg.message ?? "Unknown error")")
					}
				case let msg as NMChatMessage:
					addChatMessage(sender: msg.senderName, message: msg.message)
				case let msg as NMChatJoinedLobby:
					initializeLobby(players: msg.players)
				case let msg as NMChatPlayerJoined:
					addChatMessage(sender: "System", message: "\(msg.playerName) has joined")
					addPlayer(name: msg.playerName, id: msg.playerId)
				case let msg as NMChatPlayerLeft:
					//addChatMessage(sender: "System", message: "\(msg.playerId) has left")
					removePlayer(id: msg.playerId)
				default:
					GD.print("Received unknown binary message type")
			}
		} catch {
			GD.print("Failed to decode binary message: \(error)")
			GD.print(error.localizedDescription)
		}
	}

	private func handleMessage(message: String) {
		GD.print(message)
	}
}