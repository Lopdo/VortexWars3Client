import Foundation
import SwiftGodot

@Godot
class RegionMaskView: Node2D {
	
	var region: Region!
	
	override func _draw() {
		for tile in region.tiles {
			drawPolygon(points: getPolygonPoints(tile: tile),
						colors: [Color.white])
		}
	}

	private func getPolygonPoints(tile: MapCoord) -> PackedVector2Array {
		let relPosX = Float(tile.x - region.position.x) * TileRenderInfo.width
		let relPosY = Float(tile.y - region.position.y) * (TileRenderInfo.sideLength + TileRenderInfo.roofHeight)
		let xOffset = (tile.y % 2 == 1) ? TileRenderInfo.width / 2 : 0
		let cornerVector = Vector2(x: relPosX + xOffset, y: relPosY)

		var polygonPoints: [Vector2] = []
		
		for dir in Map.Direction.allCases {
			polygonPoints.append(cornerVector + TileRenderInfo.points[dir]!.0)
		}
		return PackedVector2Array(polygonPoints)
	}
}
