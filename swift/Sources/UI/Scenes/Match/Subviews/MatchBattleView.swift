import Foundation
import NetworkModels
import SwiftGodot

@Godot
final class MatchBattleView: Control {

	@Export
	var lblAttacker: Label!

	@Export
	var lblDefender: Label!

	private var timer: SwiftGodot.Timer!

	private var battleThrows: [NMMatchBattleThrows] = []

	override func _ready() {
		timer = SwiftGodot.Timer()
		addChild(node: timer)
		timer.waitTime = Double(Timings.battleDuration) / 1000
		timer.timeout.connect(onTimer)
	}

	func start(battle: NMMatchBattle) {
		self.battleThrows = battle.battleThrows.reversed()

		show()

		if battleThrows.count > 1 {
			timer.start()
		}
		if let firstBattleThrows = battleThrows.popLast() {
			showBattleThrows(firstBattleThrows)
		}
	}

	private func showBattleThrows(_ battleThrows: NMMatchBattleThrows) {
		lblAttacker.text = String(battleThrows.attackerThrow)
		lblDefender.text = String(battleThrows.defenderThrow)
	}

	func close() {
		hide()
	}

	private func onTimer() {
		if let firstBattleThrows = battleThrows.popLast() {
			showBattleThrows(firstBattleThrows)
		}

		if battleThrows.isEmpty {
			timer.stop()
		}
	}
}
