import Foundation
import NetworkModels
import SwiftGodot

@Godot
final class MapView: Node2D {

	@Export
	private var camera: CameraZoomAndPan!

	@Export
	private var bgTextureRect: TextureRect!

	unowned private var match: Match!

	override func _ready() {
		guard match != nil else {
			GD.print("Match and map not initialized in MapView._ready")
			return
		}

		setupDimensions()

		renderMap()
	}

	func set(match: Match) {
		self.match = match
	}

	override func _process(delta: Double) {
		if let subViewport = findSubViewport() {
			camera.setMapView(size: Vector2(from: subViewport.size))
		}
	}

	private func setupDimensions() {
		let mapRenderWidth = Float(match.map.width) * TileRenderInfo.width
		let mapRenderHeight =
			Float(match.map.height) * TileRenderInfo.rowHeight + TileRenderInfo.roofHeight

		let renderNodeWidth: Float = 800
		let renderNodeHeight: Float = 600

		let bgTextureWidth = max(mapRenderWidth, 2 * renderNodeWidth) + 2 * renderNodeWidth
		let bgTextureHeight = max(mapRenderHeight, 2 * renderNodeHeight) + 2 * renderNodeHeight

		let bgTextureRectOffsetX =
			renderNodeWidth
			+ (TileRenderInfo.width
				- renderNodeWidth.truncatingRemainder(dividingBy: TileRenderInfo.width))
		let bgTextureRectOffsetY =
			renderNodeHeight + TileRenderInfo.rowHeight
			- renderNodeHeight.truncatingRemainder(dividingBy: TileRenderInfo.rowHeight)

		bgTextureRect.setPosition(
			Vector2(x: Float(-bgTextureRectOffsetX), y: Float(-bgTextureRectOffsetY)))
		bgTextureRect.setSize(Vector2(x: Float(bgTextureWidth), y: Float(bgTextureHeight)))

		camera.mapSize = Vector2(x: Float(mapRenderWidth), y: Float(mapRenderHeight))
	}

	private func renderMap() {
		for region in match.map.regions {
			let regionView = RegionView()
			regionView.initialize(map: match.map, region: region.region)
			addChild(node: regionView)
			regionView.position = Vector2(
				x: Float(region.region.position.x) * TileRenderInfo.width,
				y: Float(region.region.position.y) * TileRenderInfo.rowHeight)

			region.regionView = regionView
		}

		// Place top layer views (like armies) after all regions are added
		for regionView in getChildren().compactMap({ $0 as? RegionView }) {
			regionView.placeTopLayerViews(to: self)
		}

		for matchRegion in match.map.regions {
			matchRegion.regionView.set(owner: matchRegion.owner, match: match)
			matchRegion.regionView.update(armySize: matchRegion.armySize)
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
