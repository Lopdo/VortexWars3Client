import Foundation
import SwiftGodot
import NetworkModels

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
	
	static func joinMatch(
		matchId: String,
		user: User,
		webSocketClient: WebSocketClient,
		onConnected: (() -> Void)? = nil,
		onJoinSuccess: @escaping (NMMatchJoined) -> Void,
		onError: @escaping (MatchError) -> Void
	) {
		webSocketClient.connectedToServer.connect {
			onConnected?()
			sendJoinMatchAuth(user: user, webSocketClient: webSocketClient, onError: onError)
		}
		
		webSocketClient.connectionClosed.connect {
			onError(.connectionClosed)
		}
		
		webSocketClient.dataReceived.connect { data in
			handleJoinMatchMessage(
				data: data,
				webSocketClient: webSocketClient,
				onJoinSuccess: onJoinSuccess,
				onError: onError
			)
		}
		
		let url = "ws://127.0.0.1:8080/match/join?id=\(matchId)"
		let result = webSocketClient.connectTo(url: url)
		if result != .ok {
			onError(.networkError(NSError(domain: "MatchService", code: Int(result.rawValue), userInfo: [NSLocalizedDescriptionKey: "Failed to connect to WebSocket"])))
		}
	}
	
	static func createMatch(
		settings: NMMatchSettings,
		user: User,
		webSocketClient: WebSocketClient,
		onConnected: (() -> Void)? = nil,
		onCreateSuccess: @escaping (NMMatchJoined) -> Void,
		onError: @escaping (MatchError) -> Void
	) {
		webSocketClient.connectedToServer.connect {
			onConnected?()
			sendCreateMatchAuth(user: user, webSocketClient: webSocketClient, onError: onError)
		}
		
		webSocketClient.connectionClosed.connect {
			onError(.connectionClosed)
		}
		
		webSocketClient.dataReceived.connect { data in
			handleCreateMatchMessage(
				settings: settings,
				data: data,
				webSocketClient: webSocketClient,
				onCreateSuccess: onCreateSuccess,
				onError: onError
			)
		}
		
		let url = "ws://127.0.0.1:8080/match/create"
		let result = webSocketClient.connectTo(url: url)
		if result != .ok {
			onError(.networkError(NSError(domain: "MatchService", code: Int(result.rawValue), userInfo: [NSLocalizedDescriptionKey: "Failed to connect to WebSocket"])))
		}
	}
	
	private static func sendJoinMatchAuth(user: User, webSocketClient: WebSocketClient, onError: @escaping (MatchError) -> Void) {
		let auth = NMPlayerAuth(playerId: user.player.id, authToken: user.sessionToken)
		
		do {
			let data = try NMEncoder.encode(auth)
			try webSocketClient.send(data: data)
			GD.print("Sent join match auth")
		} catch {
			GD.print("Failed to encode NMPlayerAuth: \(error)")
			onError(.networkError(error))
		}
	}
	
	private static func sendCreateMatchAuth(user: User, webSocketClient: WebSocketClient, onError: @escaping (MatchError) -> Void) {
		let auth = NMPlayerAuth(playerId: user.player.id, authToken: user.sessionToken)
		
		do {
			let data = try NMEncoder.encode(auth)
			try webSocketClient.send(data: data)
			GD.print("Sent create match auth")
		} catch {
			GD.print("Failed to encode NMPlayerAuth: \(error)")
			onError(.networkError(error))
		}
	}
	
	private static func handleJoinMatchMessage(
		data: PackedByteArray,
		webSocketClient: WebSocketClient,
		onJoinSuccess: @escaping (NMMatchJoined) -> Void,
		onError: @escaping (MatchError) -> Void
	) {
		do {
			let message = try NMDecoder.decode(data.asBytes())
			
			switch message {
			case let msg as NMPlayerAuthResult:
				if msg.success {
					GD.print("Join match auth successful")
					let ackData = try NMEncoder.encode(NMPlayerAuthAck())
					try webSocketClient.send(data: ackData)
				} else {
					GD.print("Join match auth failed: \(msg.message ?? "Unknown error")")
					onError(.authenticationFailed(msg.message ?? "Unknown error"))
				}
				
			case let msg as NMMatchJoined:
				GD.print("Successfully joined match: \(msg.id)")
				onJoinSuccess(msg)
				
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
					sendCreateMatchRequest(settings: settings, webSocketClient: webSocketClient, onError: onError)
				} else {
					GD.print("Create match auth failed: \(msg.message ?? "Unknown error")")
					onError(.authenticationFailed(msg.message ?? "Unknown error"))
				}
				
			case let msg as NMMatchJoined:
				GD.print("Successfully created match: \(msg.id)")
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
	
	private static func sendCreateMatchRequest(settings: NMMatchSettings, webSocketClient: WebSocketClient, onError: @escaping (MatchError) -> Void) {
		let createMatchMsg = NMCreateMatch(settings: settings)
		
		do {
			let data = try NMEncoder.encode(createMatchMsg)
			try webSocketClient.send(data: data)
			GD.print("Sent create match request")
		} catch {
			GD.print("Failed to encode NMCreateMatch: \(error)")
			onError(.networkError(error))
		}
	}
}
