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
			if results.count > 1 {
				timer.start()
			}
			reinforcements = results.reversed()
			// Start first batch immediatelly
			onTimer()
		} else {
			reinforcements += results
		}
	}

	// This methods shows all remaining reinforcements at the same time,
	// used when we get new turn message before we are done with this.
	// We don't want to hold up game because of this
	func finishDistribution() {
		timer.stop()
		for r in reinforcements {
			let region = map.region(id: Int(r.regionId))
			region.addReinforcements(dice: Int(r.dice))
		}
		reinforcements.removeAll()
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
