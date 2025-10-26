import Foundation
import SwiftGodot
import NetworkModels

@Godot
final class MatchLobbyPlayerView: Control {
	
	@Export
	var lblName: Label!

	@Export
	var lblReady: Label!

	var player: NMMatchPlayer!

	func initialize(player: NMMatchPlayer) {
		self.player = player
		lblName.text = player.name
	}
	
	func set(ready: Bool) {
		lblReady.text = ready ? "Ready" : "Not ready"
	}
}
