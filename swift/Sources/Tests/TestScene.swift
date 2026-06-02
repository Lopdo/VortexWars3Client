import Foundation
import NetworkModels
import SwiftGodot

@Godot
final class TestScene: Node {
	@Export var label: Label!

	enum Action {
		case joinMatch(String)
		case createMatch(String)
	}

	var player: String?
	var password: String = "123"
	var action: Action?
	var playerCount = 1
	var readyPlayerCount = 0

	private var goToLobby: Bool = false

	private var currentUser: User?
	private var webSocketClient: WebSocketClient?

	private var binaryMsgHandlerToken: Callable?

	override func _ready() {
		parseCommandLineArgs()
		updateLabel()

		if let player {
			login(player)
		} else {
			executeAction()
		}
	}

	private func parseCommandLineArgs() {
		let args = OS.getCmdlineUserArgs()

		var match: String?

		for arg in args {
			if arg.hasPrefix("-") && arg.contains("=") {
				let parts = arg.dropFirst().split(separator: "=", maxSplits: 1)
				guard parts.count == 2 else { continue }

				let flag = String(parts[0]).lowercased()
				let value = String(parts[1]).trimmingCharacters(
					in: CharacterSet(charactersIn: "\"'"))

				switch flag {
				case "p", "player":
					player = value
				case "pwd", "password":
					password = value
				case "m", "match":
					match = value
				case "a", "action":
					switch value.lowercased() {
					case "jm", "joinmatch":
						if let match {
							action = .joinMatch(match)
						} else {
							print(
								"Error: joinMatch action requires preceeding match parameter (-m)")
						}
					case "cm", "creatematch":
						if let match {
							action = .createMatch(match)
						} else {
							print(
								"Error: createMatch action requires preceeding match parameter (-m)"
							)
						}
					default:
						print("Unknown action type: \(value)")
					}
				case "pc", "playerCount":
					if let count = Int(value) {
						playerCount = count
					} else {
						print("Error: non-integer value in playerCount parameter: \(value)")
					}
				case "lobby":
					if let lobby = Bool(value) {
						goToLobby = lobby
					} else {
						print("Error: non-bool value in lobby parameter: \(value)")
					}
				default:
					print("Unknown flag: \(flag)")
					break
				}
			}
		}
	}

	private func executeAction() {
		guard let action else { return }

		switch action {
		case .joinMatch(let matchName):
			executeJoinMatchAction(matchName: matchName)
		case .createMatch(let matchName):
			executeCreateMatchAction(matchName: matchName)
		}
	}

	private func executeJoinMatchAction(matchName: String) {
		/*guard let currentUser else {
			print("Error: User not logged in")
			return
		}*/

		findMatch(name: matchName)
		//joinMatch(matchName: matchName, user: currentUser)
	}

	private func executeCreateMatchAction(matchName: String) {
		guard let currentUser else {
			print("Error: User not logged in")
			return
		}

		createMatch(matchName: matchName, user: currentUser)
	}

	private func updateLabel() {
		guard let label else { return }

		var text = "Player: "
		if let player {
			text += player
		} else {
			text += "None"
		}

		text += "\nPassword: \(password)"

		text += "\nAction: "
		if let action {
			switch action {
			case .joinMatch(let matchId):
				text += "joinMatch(\(matchId))"
			case .createMatch(let matchId):
				text += "createMatch(\(matchId))"
			}
		} else {
			text += "None"
		}

		label.text = text
	}

	private func handleBinaryMessage(data: PackedByteArray) {
		do {
			let message = try NMDecoder.decode(data.asBytes())
			GD.print("TestScene message received: \(message)")
			switch message {
			case let msg as NMMatchPlayerJoined:
				_ = msg
				break
			case let msg as NMMatchPlayerLeft:
				_ = msg
				break
			case let msg as NMMatchPlayerReadyStatusChanged:
				if msg.ready {
					readyPlayerCount += 1
				} else {
					readyPlayerCount -= 1
				}
				if readyPlayerCount == playerCount {
					startGame()
				}
				GD.print(
					"NMMatchPlayerReadyStatusChanged received, playerId: \(msg.playerId), isReady: \(msg.ready)"
				)
			case let msg as NMMatchStarted:
				matchStartReceived(msg: msg)
			default:
				GD.print("Received unsupported binary message type \(message)")
			}
		} catch {
			GD.print("Failed to decode binary message: \(error)")
			GD.print(error.localizedDescription)
		}
	}

	private func getAuthHeader(for player: String) -> String {
		let token = "\(player):\(password)"
		return "Authorization: Basic " + token.base64Encoded.string!
	}

	private func login(_ player: String) {
		let bodyDict: [String: String] = [
			"username": player,
			"password": password,
		]

		let jsonData = try! JSONSerialization.data(withJSONObject: bodyDict)

		NetworkManager.jsonRequest(
			node: self,
			url: "/auth/login",
			method: .post,
			headers: [getAuthHeader(for: player)],
			body: jsonData,
			completion: requestCompleted
		)
	}

	private func requestCompleted(result: Result<UserDTO, Error>) {
		switch result {
		case .success(let userDTO):
			loginCompleted(userDTO: userDTO)
		case .failure(let error):
			label.text = label.text + "\nAn error occurred in the HTTP request: \(error)"
			switch error {
			case NetworkManager.NetworkError.serverError(let code) where code == 401:
				label.text = label.text + "\nInvalid username or password."
			default:
				label.text =
					label.text
					+ "\nAn error occurred in the HTTP request. \(error.localizedDescription)"
			}
		}
	}

	private func loginCompleted(userDTO: UserDTO) {
		currentUser = User(from: userDTO)
		label.text = label.text + "\nLogin successful for user: \(userDTO.username)"
		executeAction()
	}

	private func createWebSocketClient() -> WebSocketClient {
		let client = WebSocketClient()
		binaryMsgHandlerToken = client.dataReceived.connect(handleBinaryMessage)
		addChild(node: client)
		return client
	}

	private func findMatch(name matchName: String) {
		label.text = label.text + "\nFetching matches..."
		NetworkManager.jsonRequest(
			node: self,
			url: "/match/list",
			method: .get,
			completion: {
				self.matchFetchRequestCompleted(result: $0, matchName: matchName)
			}
		)
	}

	private func matchFetchRequestCompleted(result: Result<MatchListDTO, Error>, matchName: String)
	{
		switch result {
		case .success(let matchListDTO):
			if let match = matchListDTO.matches.first(where: { $0.name == matchName }) {
				//if let match = matchListDTO.matches.first {
				joinMatch(matchId: match.id, user: currentUser!)
			} else {
				label.text = label.text + "\nMatch with name \(matchName) not found, retrying in 1s"
				OS.delayMsec(1_000)
				findMatch(name: matchName)
			}

		case .failure(let error):
			GD.print("An error occurred in the HTTP request: \(error)")
		}
	}

	private func joinMatch(matchId: String, user: User) {
		label.text = label.text + "\nJoining match: \(matchId)"

		webSocketClient = createWebSocketClient()

		MatchService.joinMatch(
			matchId: matchId,
			user: user,
			webSocketClient: webSocketClient!,
			onJoinSuccess: handleJoinSuccess,
			onError: { error in
				GD.print("Failed to join match: \(error)")
				self.label.text = self.label.text + "\nFailed to join match: \(error)"
			}
		)
	}

	private func createMatch(matchName: String, user: User) {
		label.text = label.text + "\nCreating match: \(matchName)"

		webSocketClient = createWebSocketClient()

		let settings = NMMatchSettings(mapId: "123", gameName: matchName, maxPlayers: 4)
		MatchService.createMatch(
			settings: settings,
			user: user,
			webSocketClient: webSocketClient!,
			onCreateSuccess: handleJoinSuccess,
			onError: { error in
				GD.print("Failed to create match: \(error)")
				self.label.text = self.label.text + "\nFailed to create match: \(error)"
			}
		)
	}

	func readyUp() {
		do {
			let auth = NMMatchPlayerChangeReadyStatus(ready: true)
			try webSocketClient?.send(message: auth)
		} catch {
			//TODO: add error handling
			GD.print("Failed to send message NMMatchPlayerChangeReadyStatus")
			self.label.text =
				self.label.text
				+ "\nFailed to send message NMMatchPlayerChangeReadyStatus: \(error)"
		}
	}

	func startGame() {
		do {
			try webSocketClient?.send(message: NMMatchStartRequested())
		} catch {
			//TODO: add error handling
			GD.print("Failed to send message NMMatchPlayerChangeReadyStatus")
		}
	}

	private func matchStartReceived(msg: NMMatchStarted) {
		if let match = SceneLoader.load(path: "res://Screens/Match/match_screen.tscn")
			as? MatchScreen
		{
			match.initialize(
				user: currentUser!,
				settings: msg.settings, players: msg.players, startingPlayer: msg.startingPlayer,
				mapData: msg.mapData, ws: webSocketClient!)

			changeSceneToNode(node: match)

			if let binaryMsgHandlerToken {
				webSocketClient!.dataReceived.disconnect(binaryMsgHandlerToken)
			}
		} else {
			GD.print("Failed to load MainLobby scene")
			ErrorManager.showError(message: "Failed to load MainLobby scene")
		}
	}

	private func handleJoinSuccess(client: WebSocketClient, msg: NMMatchJoined) {
		if goToLobby {
			goToLobby(msg: msg)
		} else {
			GD.print("Successfully joined match")
			self.label.text = self.label.text + "\nSuccessfully joined match"
			readyUp()
		}
	}

	private func goToLobby(msg: NMMatchJoined) {
		GD.print("Successfully joined match with ID: \(msg.id)")
		if let lobby = SceneLoader.load(path: "res://Screens/MatchLobby/match_lobby.tscn")
			as? MatchLobby
		{
			lobby.initialize(ws: webSocketClient!, user: currentUser!, players: msg.players)
			changeSceneToNode(node: lobby)
			removeChild(node: webSocketClient!)
			if let binaryMsgHandlerToken {
				webSocketClient!.dataReceived.disconnect(binaryMsgHandlerToken)
			}
		}
	}
}
