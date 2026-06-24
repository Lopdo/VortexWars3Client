import Foundation
import SwiftGodot

@Godot
final class RegionFactionView: Sprite2D {

	let defaltFont = ThemeDB.fallbackFont
	var diceText: String? = nil

	override func _ready() {
		texture = ResourceLoader.load(path: "res://res/img/faction_logoEmpty.png") as? Texture2D
		if let texture {
			offset = Vector2(x: texture.getSize().x / 2, y: texture.getSize().y / 2)
		}
	}

	func set(faction: Int?) {
		let resName: String
		if let faction {
			resName = "faction_logo\(faction)"
		} else {
			resName = "faction_logoEmpty"
		}
		texture = ResourceLoader.load(path: "res://res/img/\(resName).png") as? Texture2D
	}

	func set(dice: Int) {
		self.diceText = String(dice)
		queueRedraw()
	}

	override func _draw() {
		if let diceText {
			drawString(
				font: defaltFont, pos: Vector2(x: 22, y: 32), text: diceText, alignment: .center,
				width: 16,
				fontSize: 11)
		}
	}
}
