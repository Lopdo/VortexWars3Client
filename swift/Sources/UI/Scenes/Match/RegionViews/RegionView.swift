import Foundation
import SwiftGodot

@Godot
class RegionView: Sprite2D {

	private var map: Map!
	var region: MapRegion!

	unowned var playerOwner: MatchPlayer?

	private var borderView: RegionBorderView!
	private var bgView: RegionBGView!
	var armyView: RegionArmyView!

	func initialize(map: Map, region: MapRegion, playerOwner: MatchPlayer?) {
		self.map = map
		self.region = region
		self.playerOwner = playerOwner
	}

	override func _ready() {
		let maskView = RegionMaskView()
		maskView.initialize(region: region)
		addChild(node: maskView)

		bgView = RegionBGView()
		bgView.setRegion(region: region)
		maskView.addChild(node: bgView)

		borderView = RegionBorderView()
		borderView.initialize(map: map, mapRegion: region)
		maskView.addChild(node: borderView)

		bgView.set(race: "", color: playerOwner?.color ?? Color.lightGray)

		armyView = RegionArmyView()
		//addChild(node: armyView)

		setupMouseDetection()
	}

	func updateBorders(match: Match) {
		borderView.updateBorders(match: match)
	}

	func placeTopLayerViews(to node: Node) {
		node.addChild(node: armyView)
		let offsetX = region.center.y % 2 == 0 ? 0.0 : TileRenderInfo.width / 2
		let armyPosX =
			Float(region.center.x) * TileRenderInfo.width + TileRenderInfo.width / 2
			+ offsetX - armyView.texture!.getSize().x / 2
		let armyPosY =
			Float(region.center.y) * TileRenderInfo.rowHeight + TileRenderInfo.rowHeight / 2
			- armyView.texture!.getSize().y / 2
		armyView.position = Vector2(x: armyPosX, y: armyPosY)
	}

	private func setupMouseDetection() {
		let area = borderView.getCollisionArea()
		addChild(node: area)

		area.mouseEntered.connect(onMouseEntered)
		area.mouseExited.connect(onMouseExited)
	}

	private func onMouseEntered() {
		bgView.selfModulate =
			playerOwner?.color.lightened(amount: 0.3) ?? Color.lightGray.lightened(amount: 0.3)
	}

	private func onMouseExited() {
		bgView.selfModulate = playerOwner?.color ?? Color.lightGray
	}

}
