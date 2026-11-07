import Foundation
import SwiftGodot

extension CustomMatchView: SceneLoadable {
	static var pathToScene: String {
		"res://Screens/MainLobby/custom_match_view.tscn"
	}
}

@Godot
class CustomMatchView: Button {
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
