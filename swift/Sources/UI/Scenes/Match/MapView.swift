import Foundation
import SwiftGodot

@Godot
final class MapView: Node2D {
	 
	@Export
	private var camera: CameraZoomAndPan!

	@Export
	private var bgTextureRect: TextureRect!

	private var match: Match!

	override func _ready() {
		// For testing purposes, create a simple map
		let tiles: [Int] = [
			0, 1, 0, 2, 0,
			1, 1, 1, 2, 2,
			3, 1, 4, 2, 2,
			3, 3, 4, 4, 0,
			3, 3, 4, 4, 4
		]
		let map = Map(tiles: tiles, width: 5, height: 5)
		let players = [MatchPlayer(index: 0), MatchPlayer(index: 1)]

		match = Match(map: map, players: players)

		match.regions[0].owner = players[0]
		match.regions[2].owner = players[0]
		match.regions[1].owner = players[1]
		match.regions[3].owner = players[1]
		
		setupDimensions()

		renderMap()
	}

	private func setupDimensions() {
		let mapRenderWidth = 5 * TileRenderInfo.width
		let mapRenderHeight = 5 * TileRenderInfo.rowHeight + TileRenderInfo.roofHeight

		print("Map render dimensions: \(mapRenderWidth)x\(mapRenderHeight)")

		let renderNodeWidth: Float = 800
		let renderNodeHeight: Float = 600

		let bgTextureWidth = max(mapRenderWidth, 2 * renderNodeWidth) + 2 * renderNodeWidth
		let bgTextureHeight = max(mapRenderHeight, 2 * renderNodeHeight) + 2 * renderNodeHeight

		let bgTextureRectOffsetX = renderNodeWidth + (TileRenderInfo.width - renderNodeWidth.truncatingRemainder(dividingBy: TileRenderInfo.width))
		let bgTextureRectOffsetY = renderNodeHeight + TileRenderInfo.rowHeight - renderNodeHeight.truncatingRemainder(dividingBy: TileRenderInfo.rowHeight)

		bgTextureRect.setPosition(Vector2(x: Float(-bgTextureRectOffsetX), y: Float(-bgTextureRectOffsetY)))
		bgTextureRect.setSize(Vector2(x: Float(bgTextureWidth), y: Float(bgTextureHeight)))
		
		print("Background TextureRect positioned at (\(-bgTextureRectOffsetX), \(-bgTextureRectOffsetY)) with size \(bgTextureWidth)x\(bgTextureHeight)")

		camera.mapSize = Vector2(x: Float(mapRenderWidth), y: Float(mapRenderHeight))
		//TODO pass actual viewport size
		camera.setMapView(size: getViewportRect().size)
	}

	private func renderMap() {
		for region in match.regions {
			let regionView = RegionView()
			regionView.region = region
			addChild(node: regionView)
			let xOffset: Float = region.region.position.y % 2 == 1 ? TileRenderInfo.width / 2 : 0
			regionView.position = Vector2(x: Float(region.region.position.x) * TileRenderInfo.width + xOffset,
										  y: Float(region.region.position.y) * TileRenderInfo.rowHeight)

			regionView.updateBorders(match: match)
		}

	}

}
