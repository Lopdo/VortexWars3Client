import Foundation
import SwiftGodot

@Godot
class RegionView: Sprite2D {
	
	var region: MatchRegion!
	
	private var borderView: RegionBorderView!
	private var bgView: RegionBGView!

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
		maskView.addChild(node: borderView)

		bgView.set(race: "", color: region.owner?.color ?? Color.lightGray)
	}
	
	func updateBorders(match: Match) {
		borderView.updateBorders(match: match)
	}

}
