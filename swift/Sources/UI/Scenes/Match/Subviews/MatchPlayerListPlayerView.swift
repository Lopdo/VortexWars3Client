import Foundation
import SwiftGodot

@Godot
final class MatchPlayerListPlayerView: Control {

	@Export
	var lblName: Label!

	@Export
	var lblCurrent: Label!

	var player: MatchPlayer!

	func initialize(player: MatchPlayer, isMe: Bool) {
		self.player = player
		lblName.text = player.id + (isMe ? "*" : "")
	}

	func set(current: Bool) {
		lblCurrent.text = current ? "X" : "_"
	}

}
