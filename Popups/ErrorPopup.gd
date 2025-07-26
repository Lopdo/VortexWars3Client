extends Control
class_name ErrorPopup 

func show_error(message: String):
	$ColorRect/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PopupMessage.text = message
	show()  # This will make the whole ErrorPopup visible

func show_http_error(body: PackedByteArray):
	var error_response = JSON.parse_string(body.get_string_from_utf8())
	show_error(error_response["message"] + " - " + str(int(error_response["code"])))
	
func on_okay():
	hide()
