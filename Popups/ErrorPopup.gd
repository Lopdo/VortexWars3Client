extends Control
class_name ErrorPopup 

func show_error(message: String):
	$ColorRect/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PopupMessage.text = message
	show()  # This will make the whole ErrorPopup visible

func on_okay():
	hide()
