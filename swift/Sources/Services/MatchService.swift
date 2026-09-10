import Foundation
import NetworkModels
import SwiftGodot

enum MatchError: Error {
	case authenticationFailed(String)
	case connectionClosed
	case networkError(Error)
	case decodingError(Error)
	case unknownMessage(String)
	case matchCreationFailed(String)
	case matchJoinFailed(String)
}

struct MatchService {

	private static var binaryMsgHandlerToken: Callable?

	static func joinMatch(
		on node: Node,
		matchId: String,
		user: User,
		webSocketClient: WebSocketClient,
		onConnected: (() -> Void)? = nil,
		onJoinSuccess: ((WebSocketClient, NMMatchJoined) -> Void)? = nil,
		onReconnectSuccess: ((WebSocketClient, NMMatchJoinedInProgress) -> Void)? = nil,
		onError: @escaping (MatchError) -> Void
	) {
		webSocketClient.connectedToServer.connect {
			onConnected?()
			sendJoinMatchAuth(user: user, webSocketClient: webSocketClient, onError: onError)
		}

		webSocketClient.connectionClosed.connect {
			onError(.connectionClosed)
		}

		binaryMsgHandlerToken = webSocketClient.dataReceived.connect { data in
			handleJoinMatchMessage(
				data: data,
				webSocketClient: webSocketClient,
				onJoinSuccess: { msg in
					onJoinSuccess?(webSocketClient, msg) ?? handleJoinSuccess(node: node, client: webSocketClient, msg: msg, user: user)
				},
				onReconnectSuccess: { msg in
					onReconnectSuccess?(webSocketClient, msg) ?? handleReconnectSuccess(node: node, client: webSocketClient, msg: msg, user: user)
				},
				onError: onError
			)
		}

		let url = "ws://127.0.0.1:8080/match/join?id=\(matchId)"
		let result = webSocketClient.connectTo(url: url)
		if result != .ok {
			onError(
				.networkError(
					NSError(
						domain: "MatchService", code: Int(result.rawValue),
						userInfo: [NSLocalizedDescriptionKey: "Failed to connect to WebSocket"])))
		}
	}

	static func createMatch(
		on node: Node,
		settings: NMMatchSettings,
		user: User,
		webSocketClient: WebSocketClient,
		onConnected: (() -> Void)? = nil,
		onCreateSuccess: ((WebSocketClient, NMMatchJoined) -> Void)? = nil,
		onError: @escaping (MatchError) -> Void
	) {
		webSocketClient.connectedToServer.connect {
			onConnected?()
			sendCreateMatchAuth(user: user, webSocketClient: webSocketClient, onError: onError)
		}

		webSocketClient.connectionClosed.connect {
			onError(.connectionClosed)
		}

		binaryMsgHandlerToken = webSocketClient.dataReceived.connect { data in
			handleCreateMatchMessage(
				settings: settings,
				data: data,
				webSocketClient: webSocketClient,
				onCreateSuccess: { msg in
					onCreateSuccess?(webSocketClient, msg) ?? handleJoinSuccess(node: node, client: webSocketClient, msg: msg, user: user)
				},
				onError: onError
			)
		}

		let url = "ws://127.0.0.1:8080/match/create"
		let result = webSocketClient.connectTo(url: url)
		if result != .ok {
			onError(
				.networkError(
					NSError(
						domain: "MatchService", code: Int(result.rawValue),
						userInfo: [NSLocalizedDescriptionKey: "Failed to connect to WebSocket"])))
		}
	}

	private static func sendJoinMatchAuth(
		user: User, webSocketClient: WebSocketClient, onError: @escaping (MatchError) -> Void
	) {
		let auth = NMPlayerAuth(playerId: user.player.id, authToken: user.sessionToken)

		do {
			try webSocketClient.send(message: auth)
			GD.print("Sent join match auth")
		} catch {
			GD.print("Failed to send NMPlayerAuth: \(error)")
			onError(.networkError(error))
		}
	}

	private static func sendCreateMatchAuth(
		user: User, webSocketClient: WebSocketClient, onError: @escaping (MatchError) -> Void
	) {
		let auth = NMPlayerAuth(playerId: user.player.id, authToken: user.sessionToken)

		do {
			try webSocketClient.send(message: auth)
			GD.print("Sent create match auth")
		} catch {
			GD.print("Failed to send NMPlayerAuth: \(error)")
			onError(.networkError(error))
		}
	}

	private static func handleJoinMatchMessage(
		data: PackedByteArray,
		webSocketClient: WebSocketClient,
		onJoinSuccess: @escaping (NMMatchJoined) -> Void,
		onReconnectSuccess: @escaping (NMMatchJoinedInProgress) -> Void,
		onError: @escaping (MatchError) -> Void
	) {
		do {
			let message = try NMDecoder.decode(data.asBytes())

			switch message {
				case let msg as NMPlayerAuthResult:
					if msg.success {
						GD.print("Join match auth successful")
						try webSocketClient.send(message: NMPlayerAuthAck())
					} else {
						GD.print("Join match auth failed: \(msg.message ?? "Unknown error")")
						onError(.authenticationFailed(msg.message ?? "Unknown error"))
					}

				case let msg as NMMatchJoined:
					GD.print("Successfully joined match: \(msg.id)")
					if let binaryMsgHandlerToken {
						webSocketClient.dataReceived.disconnect(binaryMsgHandlerToken)
					}
					onJoinSuccess(msg)
				case let msg as NMMatchJoinedInProgress:
					GD.print("Successfully joined match in progress: \(msg.id)")
					if let binaryMsgHandlerToken {
						webSocketClient.dataReceived.disconnect(binaryMsgHandlerToken)
					}
					onReconnectSuccess(msg)

				case is NMMatchAlreadyStarted:
					GD.print("Match already started")
					onError(.matchJoinFailed(String(describing: message)))

				default:
					GD.print("Received unexpected message in join match: \(type(of: message))")
					onError(.unknownMessage(String(describing: message)))
			}
		} catch {
			GD.print("Failed to decode join match message: \(error)")
			onError(.decodingError(error))
		}
	}

	private static func handleCreateMatchMessage(
		settings: NMMatchSettings,
		data: PackedByteArray,
		webSocketClient: WebSocketClient,
		onCreateSuccess: @escaping (NMMatchJoined) -> Void,
		onError: @escaping (MatchError) -> Void
	) {
		do {
			let message = try NMDecoder.decode(data.asBytes())

			switch message {
				case let msg as NMPlayerAuthResult:
					if msg.success {
						GD.print("Create match auth successful")
						sendCreateMatchRequest(
							settings: settings, webSocketClient: webSocketClient, onError: onError)
					} else {
						GD.print("Create match auth failed: \(msg.message ?? "Unknown error")")
						onError(.authenticationFailed(msg.message ?? "Unknown error"))
					}

				case let msg as NMMatchJoined:
					GD.print("Successfully created match: \(msg.id)")
					if let binaryMsgHandlerToken {
						webSocketClient.dataReceived.disconnect(binaryMsgHandlerToken)
					}
					onCreateSuccess(msg)

				default:
					GD.print("Received unexpected message in create match: \(type(of: message))")
					onError(.unknownMessage(String(describing: message)))
			}
		} catch {
			GD.print("Failed to decode create match message: \(error)")
			onError(.decodingError(error))
		}
	}

	private static func sendCreateMatchRequest(
		settings: NMMatchSettings, webSocketClient: WebSocketClient,
		onError: @escaping (MatchError) -> Void
	) {
		let createMatchMsg = NMCreateMatch(settings: settings)

		do {
			try webSocketClient.send(message: createMatchMsg)
			GD.print("Sent create match request")
		} catch {
			GD.print("Failed to encode NMCreateMatch: \(error)")
			onError(.networkError(error))
		}
	}

	private static func handleJoinSuccess(node: Node, client: WebSocketClient, msg: NMMatchJoined, user: User) {
		GD.print("Successfully joined match with ID: \(msg.id)")
		let lobby = MatchLobby.loadScene()
		node.changeSceneToNode(node: lobby)
		node.removeChild(node: client)
		lobby.initialize(ws: client, user: user, players: msg.players)
	}

	private static func handleReconnectSuccess(node: Node, client: WebSocketClient, msg: NMMatchJoinedInProgress, user: User) {
		GD.print("Successfully reconnected match with ID: \(msg.id)")
		let match = MatchScreen.loadScene()
		match.initialize(
			user: user,
			settings: msg.settings, players: msg.players, startingPlayer: msg.players[Int(msg.currentPlayerIndex)].id,
			mapData: msg.map, ws: client)
		match.setCurrentState(phase: msg.state, remainingTime: msg.remainingTime)

		node.changeSceneToNode(node: match)
		node.removeChild(node: client)
	}
}
