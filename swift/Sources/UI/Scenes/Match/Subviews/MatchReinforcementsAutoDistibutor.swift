import NetworkModels
import SwiftGodot

@Godot
final class MatchReinforcementsAutoDistributor: Node {

	@Export
	private var timer: SwiftGodot.Timer!

	private var reinforcements: [NMMatchReinforcementsResult] = []
	private var map: Map!

	func initialize(map: Map) {
		self.map = map
	}

	override func _ready() {
		timer.waitTime = 0.25
		timer.timeout.connect(onTimer)
	}

	func startDistribution(results: [NMMatchReinforcementsResult]) {
		if timer.isStopped() {
			timer.start()
			reinforcements = results.reversed()
		} else {
			reinforcements += results
		}
	}

	private func onTimer() {
		if let current = reinforcements.popLast() {
			let region = map.region(id: Int(current.regionId))
			region.addReinforcements(dice: Int(current.dice))
		}

		if reinforcements.isEmpty {
			timer.stop()
		}

	}

}
