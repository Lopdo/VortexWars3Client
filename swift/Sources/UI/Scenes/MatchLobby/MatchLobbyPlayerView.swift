import Foundation
import SwiftGodot
import NetworkModels

@Godot
final class MatchLobbyPlayerView: Control {
	
	@Export
	var lblName: Label!

	@Export
	var lblReady: Label!

	var player: MatchPlayer!

	func initialize(player: MatchPlayer) {
		self.player = player
		updateName()
	}
	
	func set(ready: Bool) {
		player.isReady = ready
		lblReady.text = ready ? "Ready" : "Not ready"
	}

	func set(isCook: Bool) {
		player.isCook = isCook
		updateName()
	}

	private func updateName() {
		lblName.text = "\(player.isCook ? "*" : "") \(player.name)"
	}

}
