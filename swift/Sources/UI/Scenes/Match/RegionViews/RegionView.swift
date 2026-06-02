import Foundation
import SwiftGodot

@Godot
class RegionView: Sprite2D {

	private var map: Map!
	var region: MapRegion!

	private var borderView: RegionBorderView!
	private var bgView: RegionBGView!
	var armyView: RegionArmyView!

	var isSelected: Bool = false {
		didSet {
			bgView.isSelected = isSelected
		}
	}

	var onMouseClick: ((Int) -> Void)?

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

		bgView.set(terrain: 0, color: .lightGray)

		armyView = RegionArmyView()

		setupMouseDetection()
	}

	func set(owner: MatchPlayer?) {
		if let owner {
			bgView.set(terrain: owner.terrain, color: owner.color)
			armyView.set(race: owner.race)
		} else {
			bgView.set(terrain: 0, color: .lightGray)
			armyView.set(race: nil)
		}
	}

	func update(armySize: Int) {
		armyView.set(armySize: armySize)
	}

	func updateBorders(map: Map, owner: MatchPlayer?) {
		borderView.updateBorders(map: map, owner: owner)
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
		area.inputEvent.connect(onInput)
	}

	private func onMouseEntered() {
		bgView.isHighlighted = true
	}

	private func onMouseExited() {
		bgView.isHighlighted = false
	}

	private let clickRange = 5.0
	private var mouseDownPosition: Vector2?

	private func onInput(viewport: Node?, event: InputEvent?, shapeIdx: Int64) {
		if let mouseEvent = event as? InputEventMouseButton {
			if mouseEvent.buttonIndex == .left {
				if mouseEvent.pressed {
					mouseDownPosition = mouseEvent.position
				} else {
					if let mouseDownPosition,
						mouseEvent.position.distanceTo(mouseDownPosition) < clickRange
					{
						onMouseClick?(region.id)
						self.mouseDownPosition = nil
					}
				}
			}

		}
	}
}
