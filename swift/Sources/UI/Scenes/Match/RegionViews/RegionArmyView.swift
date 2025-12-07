import Foundation
import SwiftGodot

@Godot
final class RegionArmyView: Sprite2D {

	let defaltFont = ThemeDB.fallbackFont


	override func _ready() {
		texture = GD.load(path: "res://res/img/army_logoElves.png") as? Texture2D
		offset = Vector2(x: texture!.getSize().x / 2, y: texture!.getSize().y / 2)
	}

	override func _draw() {
		//drawRect(Rect2(position: Vector2(x: 22, y: 40), size: Vector2(x: 16, y: 10)), color: Color.white)
		drawString(font: defaltFont, pos: Vector2(x: 22, y: 32), text: "10", alignment: .center, width: 16, fontSize: 11)
	}
}
