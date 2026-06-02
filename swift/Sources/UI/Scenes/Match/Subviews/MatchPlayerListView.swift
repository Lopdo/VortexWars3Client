import Foundation
import SwiftGodot

@Godot
final class MatchPlayerListView: Control {

	@Export
	var playerList: VBoxContainer!

	func add(players: [MatchPlayer], currentPlayerId: String, user: User) {
		for player in players {
			if let playerView = SceneLoader.load(path: "res://Screens/Match/match_player.tscn")
				as? MatchPlayerListPlayerView
			{
				playerView.initialize(player: player, isMe: user.player.id == player.id)
				playerList.addChild(node: playerView)
				playerView.set(current: player.id == currentPlayerId)
			}
		}
	}

	func updateCurrentPlayer(id: String) {
		for playerView in playerList.getChildren().compactMap({ $0 as? MatchPlayerListPlayerView })
		{
			playerView.set(current: playerView.player.id == id)
		}
	}
}
