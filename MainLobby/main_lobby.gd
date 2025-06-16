extends Node2D

@onready var _client: WebSocketClient = $WebsocketScript
#@onready var _log_dest: RichTextLabel = $Panel/VBoxContainer/RichTextLabel
@onready var _line_edit: LineEdit = $MarginContainer/VBoxContainer/HBoxContainer/LineEdit
@export var chatContent: VBoxContainer
@export var playerList: VBoxContainer

func _ready() -> void:
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
	_client.send(Globals.player_id + ":" + Globals.session_token)
	__add_chat_message("System", "Chat joined...")

func _on_web_socket_client_message_received(message: String) -> void:
	info("%s" % message)
	var chat_message = JSON.parse_string(message)
	match chat_message["type"]:
		"joinedLobby":
			__initialize_lobby(chat_message)
		"chatMessage":
			__add_chat_message(chat_message["name"], chat_message["msg"])
		"playerJoined":
			#__add_chat_message("System", chat_message["name"] + " has joined")
			__add_player(chat_message["name"], chat_message["pid"])
		"playerLeft": 
			print("player left ", chat_message["pid"])
			#__add_chat_message("System", chat_message["name"] + " has left")
			__remove_player(chat_message["pid"])
	 
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

#region Chat UI

func __add_chat_message(sender: String, message: String) -> void:
	var message_label = RichTextLabel.new()
	message_label.text = "[b]" + sender + ":[/b] " + __escape_bbcode(message)
	message_label.fit_content = true
	message_label.bbcode_enabled = true
	chatContent.add_child(message_label)
	#print(chatContent.get_children())

func __escape_bbcode(bbcode_text):
	# We only need to replace opening brackets to prevent tags from being parsed.
	return bbcode_text.replace("[", "[lb]")	
	 
func __add_player(name: String, id: String) -> void:
	var player_view = ChatMemberView.new()
	player_view.playerId = id
	player_view.text = name
	playerList.add_child(player_view)
	
func __remove_player(id: String) -> void: 
	var nodes = playerList.get_children()
	for n in nodes:
		if (n as ChatMemberView).playerId == id:
			playerList.remove_child(n)

func __initialize_lobby(players: Variant) -> void:
	for player in players["players"]:
		__add_player(player["name"], player["pid"])
		 
#endregion
