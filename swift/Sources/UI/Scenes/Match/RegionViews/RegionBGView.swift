import Foundation
import SwiftGodot

@Godot
final class RegionBGView: TextureRect {

	override func _ready() {
		stretchMode = .tile
	}
	
	func setRegion(region: Region) {

		let xOffset: Float = region.position.y % 2 == 1 ? TileRenderInfo.width / 2 : 0
		let posX = -(Float(region.position.x) * TileRenderInfo.width + xOffset).truncatingRemainder(dividingBy: 100)
		let posY = -(Float(region.position.y) * TileRenderInfo.rowHeight).truncatingRemainder(dividingBy: 100)

		setPosition(Vector2(x: posX, y: posY))

		setSize(Vector2(x: Float(region.size.width) * TileRenderInfo.width + 100,
				        y: Float(region.size.height) * TileRenderInfo.rowHeight + 100))
	}

	func set(race: String, color: Color) {
		// Additional configuration logic can be added here
		texture = GD.load(path: "res://res/img/terrain_pumpkins.jpg") as? Texture2D

		selfModulate = color
	}
}
