extends Node

func _on_button_pressed() -> void:
	# Create an HTTP request node and connect its completion signal.
	_login()
	
func _on_register_pressed() -> void:
	_register()

func _login():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._http_request_completed)

	print(_auth_header())
	# Perform a GET request. The URL below returns JSON as of writing.
	var error = http_request.request("http://127.0.0.1:8080/auth/login", [_auth_header()], HTTPClient.METHOD_POST)
	if error != OK:
		push_error("An error occurred in the HTTP request.")

func _register():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._http_request_completed)

	var bodyDict: Dictionary = {
		username = $VBoxContainer/LineEditUsername.text,
		password = $VBoxContainer/LineEditPassword.text
	}
	# Perform a GET request. The URL below returns JSON as of writing.
	var error = http_request.request("http://127.0.0.1:8080/auth/register", ['Content-Type: application/json'], HTTPClient.METHOD_POST, JSON.stringify(bodyDict))
	if error != OK:
		push_error("An error occurred in the HTTP request.")
		
func _auth_header() -> String:
	var token = $VBoxContainer/LineEditUsername.text + ":" + $VBoxContainer/LineEditPassword.text
	return "Authorization: Basic " + Marshalls.utf8_to_base64(token)


func _http_request_completed(result, response_code, headers, body):
	##print(json["name"])
	print(body.get_string_from_utf8())
	var login_response = JSON.parse_string(body.get_string_from_utf8())
	Globals.session_token = login_response["sessionToken"]
	Globals.player_id = login_response["player"]["id"]
	Globals.player_name = login_response["player"]["name"]
	
	var lobby_scene = preload("res://MainLobby/main_lobby.tscn").instantiate()
	change_scene_to_node(lobby_scene)

func change_scene_to_node(node):
	var tree = get_tree()
	var cur_scene = tree.get_current_scene()
	tree.get_root().add_child(node)
	tree.get_root().remove_child(cur_scene)
	tree.set_current_scene(node)
