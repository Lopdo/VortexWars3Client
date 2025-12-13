import Foundation
import SwiftGodot

@Godot
class RegionView: Sprite2D {
	
	var region: MatchRegion!
	var map: Map!
	
	private var borderView: RegionBorderView!
	private var bgView: RegionBGView!
	private var armyView: RegionArmyView!

	override func _ready() {
		let maskView = RegionMaskView()
		maskView.region = region.region
		maskView.clipChildren = .only
		addChild(node: maskView)

		bgView = RegionBGView()
		bgView.setRegion(region: region.region)
		maskView.addChild(node: bgView)

		borderView = RegionBorderView()
		borderView.region = region
		borderView.map = map
		maskView.addChild(node: borderView)

		bgView.set(race: "", color: region.owner?.color ?? Color.lightGray)

		armyView = RegionArmyView()

		setupMouseDetection()
	}
	
	func updateBorders(match: Match) {
		borderView.updateBorders(match: match)
	}

	func placeTopLayerViews(to node: Node) {
		node.addChild(node: armyView)
		
		let offsetX = region.region.center.y % 2 == 0 ? 0.0 : TileRenderInfo.width / 2
		let armyPosX = Float(region.region.center.x) * TileRenderInfo.width + TileRenderInfo.width / 2 + offsetX - armyView.texture!.getSize().x / 2
		let armyPosY = Float(region.region.center.y) * TileRenderInfo.rowHeight + TileRenderInfo.rowHeight / 2 - armyView.texture!.getSize().y / 2
		armyView.position = Vector2(x: armyPosX, y: armyPosY)
	}

	private func setupMouseDetection() {
		let area = Area2D()
		let collision = CollisionPolygon2D()

		collision.polygon = PackedVector2Array(from: borderView.borderLine.points)
		area.addChild(node: collision)
		addChild(node: area)
		
		area.mouseEntered.connect(onMouseEntered)
		area.mouseExited.connect(onMouseExited)
	}

	private func onMouseEntered() {
		bgView.selfModulate = region.owner?.color.lightened(amount: 0.3) ?? Color.lightGray.lightened(amount: 0.3)
	}

	private func onMouseExited() {
		bgView.selfModulate = region.owner?.color ?? Color.lightGray
	}

}
