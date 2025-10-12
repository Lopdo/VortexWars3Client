import Foundation
import SwiftGodot

@Godot
class MatchView: Button {
	@Export
	var lblName: Label!

	@Export
	var lblPlayerCount: Label! 

	var matchId: String = ""

	func setup(with match: MatchDTO) {
		matchId = match.id
		lblName.text = match.id
		lblPlayerCount.text = "\(match.playerCount)"
	}
}
