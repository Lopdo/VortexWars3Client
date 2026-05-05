import Foundation
import SwiftGodot

@Godot
final class MatchPlayerListPlayerView: Control {

	@Export
	var lblName: Label!

	@Export
	var lblCurrent: Label!

	var player: MatchPlayer!

	func initialize(player: MatchPlayer) {
		self.player = player
		lblName.text = player.id
	}

	func set(current: Bool) {
		lblCurrent.text = current ? "X" : "O"
	}

}
