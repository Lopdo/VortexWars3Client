import Foundation
import SwiftGodot

@Godot
final class MainScene: CanvasLayer {

	@Export
	var errorLayer: CanvasLayer!

	@Export
	var gameLayer: CanvasLayer!

	override func _ready() {
		createPopup()
	
		if let loginScene = GD.load(path: "res://Screens/Login/login_screen.tscn") as? PackedScene {
			let login = loginScene.instantiate()
			gameLayer.addChild(node: login)
		}
		//var login = GD.load("res://Screens/Login/login_screen.tscn").instantiate()
		//gameLayer.addChild(node: login)
	}
	
	func createPopup() {
		ErrorPopup.canvasLayer = errorLayer
	}
	
}	