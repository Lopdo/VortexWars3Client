import Foundation
import SwiftGodot
import NetworkModels

@Godot
final class MapView: Node2D {
	 
	@Export
	private var camera: CameraZoomAndPan!

	@Export
	private var bgTextureRect: TextureRect!

	private var match: Match!

	override func _ready() {
		guard match != nil else {
			GD.print("Match and map not initialized in MapView._ready")
			return
		}

		setupDimensions()

		renderMap()
	}
	
	func set(mapData: NMMatchMapData) {
		// For testing purposes, create a simple map
		/*let tiles: [Int] = [
				0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 7, 7, 0,
				0, 1, 1, 1, 2, 2, 2, 0, 0, 7, 7, 7, 7, 7, 0,
				0, 1, 1, 1, 2, 2, 2, 2, 7, 7, 7, 7, 7, 7, 0,
				1, 1, 1, 2, 2, 2, 2, 2, 7, 7, 7, 7, 7, 0, 0,
				1, 1, 1, 1, 2, 2, 2, 2, 2, 5, 5, 7, 7, 0, 0,
				1, 1, 1, 3, 2, 2, 5, 5, 5, 5, 5, 7, 0, 0, 0,
				1, 1, 3, 3, 3, 3, 5, 5, 5, 5, 5, 0, 0, 0, 0,
				0, 3, 3, 3, 3, 3, 4, 5, 5, 5, 5, 5, 0, 0, 0,
				0, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 6, 6, 0, 0,
				0, 0, 3, 3, 3, 4, 4, 4, 5, 5, 6, 6, 6, 0, 0,
				0, 0, 3, 3, 3, 4, 4, 4, 4, 6, 6, 6, 6, 0, 0,
				0, 3, 3, 3, 0, 0, 4, 4, 4, 6, 6, 6, 6, 0, 0,
				0, 0, 3, 3, 0, 0, 0, 0, 6, 6, 6, 6, 6, 0, 0,
				0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 6, 0, 0, 0,
				0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
				*/
		let map = Map(tiles: mapData.tiles.map { Int($0) },
					  width: Int(mapData.width), 
					  height: Int(mapData.height))
		let players = [MatchPlayer(index: 0), MatchPlayer(index: 1)]

		match = Match(map: map, players: players)

		match.regions[0].owner = players[0]
		match.regions[2].owner = players[0]
		match.regions[1].owner = players[1]
		match.regions[3].owner = players[1]
		
	}

	override func _process(delta: Double) {
		if let subViewport = findSubViewport() {
			camera.setMapView(size: Vector2(from: subViewport.size))
		}
	}

	private func setupDimensions() {
		let mapRenderWidth = Float(match.map.width) * TileRenderInfo.width
		let mapRenderHeight = Float(match.map.height) * TileRenderInfo.rowHeight + TileRenderInfo.roofHeight

		let renderNodeWidth: Float = 800
		let renderNodeHeight: Float = 600

		let bgTextureWidth = max(mapRenderWidth, 2 * renderNodeWidth) + 2 * renderNodeWidth
		let bgTextureHeight = max(mapRenderHeight, 2 * renderNodeHeight) + 2 * renderNodeHeight

		let bgTextureRectOffsetX = renderNodeWidth + (TileRenderInfo.width - renderNodeWidth.truncatingRemainder(dividingBy: TileRenderInfo.width))
		let bgTextureRectOffsetY = renderNodeHeight + TileRenderInfo.rowHeight - renderNodeHeight.truncatingRemainder(dividingBy: TileRenderInfo.rowHeight)

		bgTextureRect.setPosition(Vector2(x: Float(-bgTextureRectOffsetX), y: Float(-bgTextureRectOffsetY)))
		bgTextureRect.setSize(Vector2(x: Float(bgTextureWidth), y: Float(bgTextureHeight)))
		
		camera.mapSize = Vector2(x: Float(mapRenderWidth), y: Float(mapRenderHeight))
	}

	private func renderMap() {
		for region in match.regions {
			let regionView = RegionView()
			regionView.region = region
			regionView.map = match.map
			addChild(node: regionView)
			regionView.position = Vector2(x: Float(region.region.position.x) * TileRenderInfo.width,
										  y: Float(region.region.position.y) * TileRenderInfo.rowHeight)

			regionView.updateBorders(match: match)
		}
		
		// Place top layer views (like armies) after all regions are added
		for regionView in getChildren().compactMap({ $0 as? RegionView }) {
			regionView.placeTopLayerViews(to: self)
		}
	}
	
	private func findSubViewport() -> SubViewport? {
		var current = getParent()
		while current != nil {
			if let subViewport = current as? SubViewport {
				return subViewport
			}
			current = current?.getParent()
		}
		return nil
	}

}
