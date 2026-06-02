import Foundation
import NetworkModels
import SwiftGodot

@Godot
final class WebSocketClient: Node {
	var tlsOptions: TLSOptions? = nil

	var socket = WebSocketPeer()
	var lastState: WebSocketPeer.State = .closed

	@Signal var connectedToServer: SimpleSignal
	@Signal var connectionClosed: SimpleSignal
	@Signal var textReceived: SignalWithArguments<String>
	@Signal var dataReceived: SignalWithArguments<PackedByteArray>

	func connectTo(url: String) -> GodotError {
		let err = socket.connectToUrl(url, tlsClientOptions: tlsOptions)
		if err != .ok {
			return err
		}

		lastState = socket.getReadyState()
		return .ok
	}

	@discardableResult
	func send(message: String) -> GodotError {
		return socket.sendText(message: message)
	}

	func send(data: [UInt8]) throws {
		let err = socket.send(message: PackedByteArray(data))
		if err != .ok {
			throw NSError(
				domain: "WebSocketClient", code: Int(err.rawValue),
				userInfo: [NSLocalizedDescriptionKey: "Error sending binary message: \(err)"])
		}
	}

	func send(message: any NetworkMessage) throws {
		let data = try NMEncoder.encode(message)
		try send(data: data)
	}

	private func checkMessage() {
		if socket.getAvailablePacketCount() < 1 {
			return
		}
		let pkt = socket.getPacket()
		if socket.wasStringPacket() {
			textReceived.emit(pkt.getStringFromUtf8())
		} else {
			dataReceived.emit(pkt)
		}
	}

	func close(code: Int32 = 1000, reason: String = "") {
		socket.close(code: code, reason: reason)
		lastState = socket.getReadyState()
	}

	func clear() {
		socket = WebSocketPeer()
		lastState = socket.getReadyState()
	}

	func getSocket() -> WebSocketPeer {
		return socket
	}

	private func poll() {
		if socket.getReadyState() != .closed {
			socket.poll()
		}

		let state = socket.getReadyState()

		if lastState != state {
			lastState = state
			if state == .open {
				connectedToServer.emit()
			} else if state == .closed {
				connectionClosed.emit()
			}
		}
		while socket.getReadyState() == .open && socket.getAvailablePacketCount() > 0 {
			checkMessage()
		}
	}

	override func _process(delta: Double) {
		poll()
	}
}
