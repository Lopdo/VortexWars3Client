import Foundation
import SwiftGodot

@Godot
final class RegionArmyView: Sprite2D {

	let defaltFont = ThemeDB.fallbackFont
	var armySize: String? = nil

	override func _ready() {
		texture = ResourceLoader.load(path: "res://res/img/army_logoEmpty.png") as? Texture2D
		if let texture {
			offset = Vector2(x: texture.getSize().x / 2, y: texture.getSize().y / 2)
		}
	}

	func set(race: Int?) {
		let resName: String
		if let race {
			resName = "army_logo\(race)"
		} else {
			resName = "army_logoEmpty"
		}
		texture = ResourceLoader.load(path: "res://res/img/\(resName).png") as? Texture2D
	}

	func set(armySize: Int) {
		self.armySize = String(armySize)
	}

	override func _draw() {
		if let armySize {
			drawString(
				font: defaltFont, pos: Vector2(x: 22, y: 32), text: armySize, alignment: .center,
				width: 16,
				fontSize: 11)
		}
	}
}
