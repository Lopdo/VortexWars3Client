extends CanvasLayer

func _ready():
	create_popup()
	
	var login = preload("res://Screens/Login/login_screen.tscn").instantiate()
	add_child(login)
	
func create_popup():
	var popup = preload("res://Popups/ErrorPopup.tscn").instantiate()
	$ErrorLayer.add_child(popup)
	popup.hide()
	Globals.error_popup = popup
