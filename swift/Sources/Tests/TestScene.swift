import Foundation
import SwiftGodot
import NetworkModels

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
	
	private var currentUser: User?
	private var webSocketClient: WebSocketClient?

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
				let value = String(parts[1]).trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
				
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
								print("Error: joinMatch action requires preceeding match parameter (-m)")
							}
						case "cm", "creatematch":
							if let match {
								action = .createMatch(match)
							} else {
								print("Error: createMatch action requires preceeding match parameter (-m)")
							}
						default:
							print("Unknown action type: \(value)")
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
		case .joinMatch(let matchId):
			executeJoinMatchAction(matchId: matchId)
		case .createMatch(let matchId):
			executeCreateMatchAction(matchId: matchId)
		}
	}
	
	private func executeJoinMatchAction(matchId: String) {
		guard let currentUser else {
			print("Error: User not logged in")
			return
		}
		
		joinMatch(matchId: matchId, user: currentUser)
	}
	
	private func executeCreateMatchAction(matchId: String) {
		guard let currentUser else {
			print("Error: User not logged in")
			return
		}
		
		createMatch(matchName: matchId, user: currentUser)
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
	
	private func getAuthHeader(for player: String) -> String {
		let token = "\(player):\(password)"
		return "Authorization: Basic " + token.base64Encoded.string!
	}
	
	private func login(_ player: String) {
		let bodyDict: [String: String] = [
			"username": player,
			"password": password
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
						ErrorManager.showError(message: "Invalid username or password.")
					default:
							ErrorManager.showError(message: "An error occurred in the HTTP request. \(error.localizedDescription)")
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
		addChild(node: client)
		return client
	}
	
	private func joinMatch(matchId: String, user: User) {
		label.text = label.text + "\nJoining match: \(matchId)"
		
		webSocketClient = createWebSocketClient()
		
		MatchService.joinMatch(
			matchId: matchId,
			user: user,
			webSocketClient: webSocketClient!,
			onJoinSuccess: { joinMsg in
				GD.print("Successfully joined match")
				self.label.text = self.label.text + "\nSuccessfully joined match"
			},
			onError: { error in
				GD.print("Failed to join match: \(error)")
				self.label.text = self.label.text + "\nFailed to join match: \(error)"
			}
		)
	}
	
	private func createMatch(matchName: String, user: User) {
		label.text = label.text + "\nCreating match: \(matchName)"
		
		webSocketClient = createWebSocketClient()
		
		MatchService.createMatch(
			settings: NMMatchSettings(mapId: "", gameName: matchName, maxPlayers: 4),
			user: user,
			webSocketClient: webSocketClient!,
			onCreateSuccess: { joinMsg in
				GD.print("Successfully created match")
				self.label.text = self.label.text + "\nSuccessfully created match"
			},
			onError: { error in
				GD.print("Failed to create match: \(error)")
				self.label.text = self.label.text + "\nFailed to create match: \(error)"
			}
		)
	}
}
