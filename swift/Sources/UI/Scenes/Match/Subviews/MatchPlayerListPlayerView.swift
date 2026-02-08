import Foundation
import SwiftGodot

@Godot
final class MatchPlayerListPlayerView: Control {

	@Export
	var lblName: Label!

	@Export
	var lblCurrent: Label!

	var player: MatchPlayer!

	func initialize(player: MatchPlayer, isCurrent: Bool) {
		self.player = player
		lblName.text = player.id
		set(current: isCurrent)
	}
	
	func set(current: Bool) {
		lblCurrent.text = current ? "X" : "O"
	}

}
