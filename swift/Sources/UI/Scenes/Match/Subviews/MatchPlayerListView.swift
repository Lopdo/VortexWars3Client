import Foundation
import SwiftGodot

@Godot
final class MatchPlayerListView: Control {

	@Export
	var playerList: VBoxContainer!

	func add(players: [MatchPlayer], currentPlayerId: String) {
		for player in players {
			if let playerView = SceneLoader.load(path: "res://Screens/Match/match_player.tscn") as? MatchPlayerListPlayerView {
				playerView.initialize(player: player, isCurrent: player.id == currentPlayerId)
				playerList.addChild(node: playerView)
			}
		}
	}

	func updateCurrentPlayer(id: String) {
		for playerView in playerList.getChildren().compactMap({ $0 as? MatchPlayerListPlayerView }) {
			playerView.set(current: playerView.player.id == id)
		}
	}
}
