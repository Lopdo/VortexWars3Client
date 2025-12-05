import Foundation
import SwiftGodot
import NetworkModels

@Godot
final class MatchLobbyPlayerView: Control {
	
	@Export
	var lblName: Label!

	@Export
	var lblReady: Label!

	var player: MatchLobbyPlayer!

	func initialize(player: MatchLobbyPlayer) {
		self.player = player
		updateName()
		set(ready: player.isReady)
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
