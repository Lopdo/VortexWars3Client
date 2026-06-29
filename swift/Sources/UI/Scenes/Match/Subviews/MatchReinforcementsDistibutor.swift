import NetworkModels
import SwiftGodot

@Godot
final class MatchReinforcementsDistributor: Node {

	@Export
	private var timer: SwiftGodot.Timer!

	private var reinforcements: [NMMatchReinforcementsResult] = []
	private var map: Map!

	override func _ready() {
		timer.waitTime = 0.25
		timer.timeout.connect(onTimer)
	}

	func startDistribution(results: [NMMatchReinforcementsResult], map: Map) {
		timer.start()
		self.map = map
		reinforcements = results.reversed()
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
