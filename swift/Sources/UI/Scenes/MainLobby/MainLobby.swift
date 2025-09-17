import Foundation
import SwiftGodot

@Godot
final class MainLobby: Node {
	// Placeholder for future implementation
	//oprivate let client = WebSocketClient()
	//ovar ws = NSURLSessionWebSocketTask()
	private let client = WebSocketClient()

	@Export
	var lineEdit: LineEdit!
	@Export
	var chatContent: VBoxContainer!
	@Export
	var playerList: VBoxContainer!

	private var user: User!
	
	override func _ready() {
		addChild(node: client)
		//connectToWebSocket()

		client.connectedToServer.connect(connectedToServer)
		client.connectionClosed.connect {
			GD.print("Client just disconnected with code: \(self.client.socket.getCloseCode()), reason: \(self.client.socket.getCloseReason())")
		}
		client.textReceived.connect(handleMessage)
		client.dataReceived.connect(handleBinaryMessage)
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
	
	private func initializeLobby(players: Variant) {
		if let playersArray = players as? [Variant] {
			for player in playersArray {
				if let playerDict = player as? [String: Any],
				   let name = playerDict["name"] as? String,
				   let pid = playerDict["pid"] as? String {
					addPlayer(name: name, id: pid)
				}
			}
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
		client.send(message: "\(user.player.id):\(user.sessionToken)")
		addChatMessage(sender: "System", message: "Chat joined...")
	}

	private func handleBinaryMessage(data: PackedByteArray) {
		GD.print("Received binary message of size: \(data.size())")
		// Handle binary message if needed
	}

	private func handleMessage(message: String) {
		GD.print(message)
		if let data = message.data(using: .utf8) {
			if let chatMessage = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
			   let type = chatMessage["type"] as? String {
				switch type {
				case "joinedLobby":
					//initializeLobby(players: chatMessage["players"])
					break
				case "chatMessage":
					if let name = chatMessage["name"] as? String,
					   let msg = chatMessage["msg"] as? String {
						addChatMessage(sender: name, message: msg)
					}
				case "playerJoined":
					if let name = chatMessage["name"] as? String,
					   let pid = chatMessage["pid"] as? String {
						addChatMessage(sender: "System", message: "\(name) has joined")
						addPlayer(name: name, id: pid)
					}
				case "playerLeft":
					if let name = chatMessage["name"] as? String,
					   let pid = chatMessage["pid"] as? String {
						addChatMessage(sender: "System", message: "\(name) has left")
						removePlayer(id: pid)
					}
				default:
					GD.print("Unknown message type: \(type)")
				}
			} else {
				GD.print("Failed to parse JSON message")
			}
		} else {
			GD.print("Failed to decode message as UTF-8 string")
		}
	}
}