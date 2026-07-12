import NetworkModels
import SwiftGodot

@Godot
final class MatchReinforcementsManualDistributor: Node {

	@Export
	private var timer: SwiftGodot.Timer!

	@Export
	private var lblDice: Label!

	private var dice: Int! {
		didSet {
			lblDice.text = String(dice)
		}
	}

	private var map: Map!

	private var reinforcementsBuffer: [Int: Int] = [:]
	private var reinforcementsPendingConfirmation: [Int: Int] = [:]
	private var callback: (([Int: Int]) -> Void)?

	func initialize(map: Map) {
		self.map = map
	}

	override func _ready() {
		timer.waitTime = 1
		timer.timeout.connect(onTimer)
	}

	func startDistribution(dice: Int, sendReinforcements: @escaping ([Int: Int]) -> Void) {
		timer.start()
		self.dice = dice
		self.callback = sendReinforcements
		lblDice.show()
		lblDice.text = String(dice)
	}

	func confirm(reinforcements: [NMMatchReinforcementsResult]) {
		for result in reinforcements {
			let regionId = Int(result.regionId)
			guard let placed = reinforcementsPendingConfirmation[regionId]
			else {
				continue
			}

			if placed == result.dice {
				reinforcementsPendingConfirmation.removeValue(forKey: regionId)
			} else {
				let diff: Int = placed - Int(result.dice)
				map.region(id: regionId).dice -= diff
				dice += diff
			}
		}
		reinforcementsPendingConfirmation.removeAll()
	}

	func stopDistribution() {
		timer.stop()
		lblDice.hide()
		onTimer()
	}

	private func onTimer() {
		if reinforcementsBuffer.isEmpty {
			return
		}

		callback?(reinforcementsBuffer)
		for regionId in reinforcementsBuffer.keys {
			reinforcementsPendingConfirmation[regionId] = (reinforcementsPendingConfirmation[regionId] ?? 0) + reinforcementsBuffer[regionId]!
		}
		reinforcementsBuffer.removeAll()
	}

	func regionSelected(region: MatchRegion) {
		guard !timer.isStopped() else { return }
		guard dice > 0, region.dice < region.maxDice else { return }

		region.addReinforcements(dice: 1)
		dice -= 1

		reinforcementsBuffer[region.id] = (reinforcementsBuffer[region.id] ?? 0) + 1

		if dice == 0 {
			stopDistribution()
		}
	}

}
