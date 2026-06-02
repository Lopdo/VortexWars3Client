import Foundation
import SwiftGodot

@Godot
final class RegionBGView: TextureRect {

	var ownerColor: Color = .lightGray

	var isSelected: Bool = false {
		didSet {
			updateState()
		}
	}
	var isHighlighted: Bool = false {
		didSet {
			updateState()
		}
	}

	override func _ready() {
		stretchMode = .tile
	}

	func setRegion(region: MapRegion) {
		let posX = -(Float(region.position.x) * TileRenderInfo.width).truncatingRemainder(
			dividingBy: 100)
		let posY = -(Float(region.position.y) * TileRenderInfo.rowHeight).truncatingRemainder(
			dividingBy: 100)

		setPosition(Vector2(x: posX, y: posY))

		setSize(
			Vector2(
				x: Float(region.size.width) * TileRenderInfo.width + 100,
				y: Float(region.size.height) * TileRenderInfo.rowHeight + 100))
	}

	func set(terrain: Int, color: Color) {
		// Additional configuration logic can be added here
		texture = GD.load(path: "res://res/img/terrain_\(terrain).png") as? Texture2D

		ownerColor = color
		selfModulate = color
	}

	private func updateState() {
		if isSelected {
			selfModulate = ownerColor.lightened(amount: 0.5)
		} else if isHighlighted {
			selfModulate = ownerColor.lightened(amount: 0.3)
		} else {
			selfModulate = ownerColor
		}
	}

}
