import Foundation
import NetworkModels
import SwiftGodot

@Godot
final class MatchBattleView: Control {

	@Export
	var lblAttacker: Label!

	@Export
	var lblDefender: Label!

	func startBattle(battles: [NMMatchBattle]) {
		show()
		lblAttacker.text = String(battles.first?.battleThrows.first?.attackerThrow ?? 0)
		lblDefender.text = String(battles.first?.battleThrows.first?.defenderThrow ?? 0)
	}

	func close() {
		hide()
	}
}
