import Foundation
import SwiftGodot

@Godot
final class RegionArmyView: Sprite2D {

	let defaltFont = ThemeDB.fallbackFont
	var armySize: String? = nil

	override func _ready() {
		texture = ResourceLoader.load(path: "res://res/img/army_logoElves.png") as? Texture2D
		if let texture {
			offset = Vector2(x: texture.getSize().x / 2, y: texture.getSize().y / 2)
		}
	}

	func set(race: String?) {
		texture = ResourceLoader.load(path: "res://res/img/army_logoElves.png") as? Texture2D
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
