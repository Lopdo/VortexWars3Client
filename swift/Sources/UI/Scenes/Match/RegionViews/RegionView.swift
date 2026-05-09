import Foundation
import SwiftGodot

@Godot
class RegionView: Sprite2D {

	private var map: Map!
	var region: MapRegion!

	//unowned var playerOwner: MatchPlayer?

	private var borderView: RegionBorderView!
	private var bgView: RegionBGView!
	var armyView: RegionArmyView!

	func initialize(map: Map, region: MapRegion) {
		self.map = map
		self.region = region
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

		bgView.set(terrain: nil, color: .lightGray)

		armyView = RegionArmyView()
		//addChild(node: armyView)

		setupMouseDetection()
	}

	func set(owner: MatchPlayer?, match: Match) {
		if let owner {
			bgView.set(terrain: "", color: owner.color)
			armyView.set(race: "")
		} else {
			bgView.set(terrain: nil, color: .lightGray)
			armyView.set(race: nil)
		}

		borderView.updateBorders(match: match, owner: owner)
	}

	func update(armySize: Int) {
		armyView.set(armySize: armySize)
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
		bgView.onMouseEntered()
	}

	private func onMouseExited() {
		bgView.onMouseExited()
	}

}
