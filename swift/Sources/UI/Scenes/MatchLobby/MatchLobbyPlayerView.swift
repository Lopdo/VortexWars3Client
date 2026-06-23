import Foundation
import NetworkModels
import SwiftGodot

@Godot
final class MatchLobbyPlayerView: Control {

	@Export
	var imgFaction: TextureRect!

	@Export
	var lblName: Label!

	@Export
	var lblReady: Label!

	var player: MatchLobbyPlayer!

	func initialize(player: MatchLobbyPlayer) {
		self.player = player
		updateName()
		set(ready: player.isReady)
		set(faction: player.faction)
		set(terrain: player.terrain)
	}

	func set(ready: Bool) {
		player.isReady = ready
		lblReady.text = ready ? "Ready" : "Not ready"
	}

	func set(isCook: Bool) {
		player.isCook = isCook
		updateName()
	}

	func set(faction: Int) {
		let resName = "army_logo\(faction)"
		imgFaction.texture = ResourceLoader.load(path: "res://res/img/\(resName).png") as? Texture2D
	}

	func set(terrain: Int) {

	}

	private func updateName() {
		lblName.text = "\(player.isCook ? "*" : "") \(player.name)"
	}

}
