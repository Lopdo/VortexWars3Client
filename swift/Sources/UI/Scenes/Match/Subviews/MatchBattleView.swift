import Foundation
import NetworkModels
import SwiftGodot

@Godot
final class MatchBattleView: Control {

	@Export
	var lblAttacker: Label!

	@Export
	var lblDefender: Label!

	func start(battle: NMMatchBattle) {
		show()
		lblAttacker.text = String(battle.battleThrows.first?.attackerThrow ?? 0)
		lblDefender.text = String(battle.battleThrows.first?.defenderThrow ?? 0)
	}

	func close() {
		hide()
	}
}
