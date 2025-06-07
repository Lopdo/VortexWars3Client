extends Node2D

@onready var _client: WebSocketClient = $WebsocketScript
#@onready var _log_dest: RichTextLabel = $Panel/VBoxContainer/RichTextLabel
@onready var _line_edit: LineEdit = $MarginContainer/VBoxContainer/HBoxContainer/LineEdit

func _ready() -> void:
	$MarginContainer/VBoxContainer/Label.text = Globals.player_name
	
	print(Globals.session_token)
	
	_connet_to_ws()
	

func info(msg: String) -> void:
	print(msg)
	#_log_dest.add_text(str(msg) + "\n")


#region Client signals
func _on_web_socket_client_connection_closed() -> void:
	var ws := _client.get_socket()
	info("Client just disconnected with code: %s, reson: %s" % [ws.get_close_code(), ws.get_close_reason()])


func _on_web_socket_client_connected_to_server() -> void:
	info("Client just connected with protocol: %s" % _client.get_socket().get_selected_protocol())


func _on_web_socket_client_message_received(message: String) -> void:
	info("%s" % message)
#endregion

#region UI signals
func _on_send_pressed() -> void:
	if _line_edit.text.is_empty():
		return

	info("Sending message: %s" % [_line_edit.text])
	_client.send(_line_edit.text)
	_line_edit.text = ""


func _connet_to_ws() -> void:
	
	var host = "127.0.0.1:8080/chat/lobby"
	info("Connecting to host: %s." % [host])
	var err := _client.connect_to_url(host)
	if err != OK:
		info("Error connecting to host: %s" % [host])
		return
#endregion
