import Foundation
import SwiftGodot

@Godot
final class WebSocketClient: Node {
	/*@Export
	var handshakeHeaders: [String] = []

	@Export
	var supportedProtocols: [String] = []
*/

	var tlsOptions: TLSOptions? = nil

	var socket = WebSocketPeer()
	var lastState: WebSocketPeer.State = .closed

	@Signal var connectedToServer: SimpleSignal
	@Signal var connectionClosed: SimpleSignal
	@Signal var textReceived: SignalWithArguments<String>
	@Signal var dataReceived: SignalWithArguments<PackedByteArray>

	func connectTo(url: String) -> GodotError {
		//socket.supportedProtocols = supportedProtocols
		//socket.handshakeHeaders = handshakeHeaders

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
			throw NSError(domain: "WebSocketClient", code: Int(err.rawValue), userInfo: [NSLocalizedDescriptionKey: "Error sending binary message: \(err)"])
		}
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
/*class_name WebSocketClient
extends Node

@export var handshake_headers: PackedStringArray
@export var supported_protocols: PackedStringArray
var tls_options: TLSOptions = null

var socket := WebSocketPeer.new()
var last_state := WebSocketPeer.STATE_CLOSED

signal connected_to_server()
signal connection_closed()
signal message_received(message: Variant)

func connect_to_url(url: String) -> int:
	socket.supported_protocols = supported_protocols
	socket.handshake_headers = handshake_headers

	var err := socket.connect_to_url(url, tls_options)
	if err != OK:
		return err

	last_state = socket.get_ready_state()
	return OK


func send(message: String) -> int:
	if typeof(message) == TYPE_STRING:
		return socket.send_text(message)
	return socket.send(var_to_bytes(message))


func get_message() -> Variant:
	if socket.get_available_packet_count() < 1:
		return null
	var pkt := socket.get_packet()
	if socket.was_string_packet():
		return pkt.get_string_from_utf8()
	return bytes_to_var(pkt)


func close(code: int = 1000, reason: String = "") -> void:
	socket.close(code, reason)
	last_state = socket.get_ready_state()


func clear() -> void:
	socket = WebSocketPeer.new()
	last_state = socket.get_ready_state()


func get_socket() -> WebSocketPeer:
	return socket


func poll() -> void:
	if socket.get_ready_state() != socket.STATE_CLOSED:
		socket.poll()

	var state := socket.get_ready_state()

	if last_state != state:
		last_state = state
		if state == socket.STATE_OPEN:
			connected_to_server.emit()
		elif state == socket.STATE_CLOSED:
			connection_closed.emit()
	while socket.get_ready_state() == socket.STATE_OPEN and socket.get_available_packet_count():
		message_received.emit(get_message())


func _process(_delta: float) -> void:
	poll()
*/