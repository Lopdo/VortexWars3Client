import Foundation
import NetworkModels
import SwiftGodot

extension CustomMatchLobbyPlayerView: SceneLoadable {
	static var pathToScene: String {
		"res://Screens/MatchLobby/custom_match_lobby_player.tscn"
	}
}

@Godot
final class CustomMatchLobbyPlayerView: Control {

	@Export
	var imgFaction: TextureRect!

	@Export
	var lblName: Label!

	@Export
	var lblReady: Label!

	var player: CustomLobbyPlayer!

	func initialize(player: CustomLobbyPlayer) {
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
		let resName = "faction_logo\(faction)"
		imgFaction.texture = ResourceLoader.load(path: "res://res/img/\(resName).png") as? Texture2D
	}

	func set(terrain: Int) {

	}

	private func updateName() {
		lblName.text = "\(player.isCook ? "*" : "") \(player.name)"
	}

}
