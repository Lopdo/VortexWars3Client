import Foundation
import SwiftGodot

@Godot
final class MatchPlayerListView: Control {

	@Export
	var playerList: VBoxContainer!

	func add(players: [MatchPlayer], currentPlayerId: String, user: User, match: Match) {
		for player in players {
			if let playerView = SceneLoader.load(path: "res://Screens/Match/match_player.tscn")
				as? MatchPlayerListPlayerView
			{
				playerView.initialize(player: player, isMe: user.player.id == player.id, match: match)
				playerList.addChild(node: playerView)
				playerView.set(current: player.id == currentPlayerId)
				playerView.set(strength: player.strength)
				if player.attackBoosts == 0 {
					playerView.disableAttackBoosts()
				} else {
					playerView.setAttackBoost(count: player.attackBoosts)
				}
				if player.defenceBoosts == 0 {
					playerView.disableDefenceBoosts()
				} else {
					playerView.setDefenceBoost(count: player.defenceBoosts)
				}
			}
		}
	}

	func updateCurrentPlayer(id: String) {
		for playerView in playerList.getChildren().compactMap({ $0 as? MatchPlayerListPlayerView }) {
			playerView.set(current: playerView.player.id == id)
		}
	}

	func update(strength: Int, playerIndex: Int) {
		if let playerView = playerList.getChildren().compactMap({ $0 as? MatchPlayerListPlayerView }).first(where: { $0.player.index == playerIndex })
		{
			playerView.set(strength: strength)
		}
	}

	func updateAttackBoost(count: Int, playerId: String) {
		if let playerView = playerList.getChildren().compactMap({ $0 as? MatchPlayerListPlayerView }).first(where: { $0.player.id == playerId }) {
			playerView.setAttackBoost(count: count)
		}
	}

	func updateDefenceBoost(count: Int, playerId: String) {
		if let playerView = playerList.getChildren().compactMap({ $0 as? MatchPlayerListPlayerView }).first(where: { $0.player.id == playerId }) {
			playerView.setDefenceBoost(count: count)
		}
	}

	func setAttackBoost(active: Bool, playerId: String) {
		if let playerView = playerList.getChildren().compactMap({ $0 as? MatchPlayerListPlayerView }).first(where: { $0.player.id == playerId }) {
			playerView.setAttackBoost(active: active)
		}
	}

	func setDefenceBoost(active: Bool, playerId: String) {
		if let playerView = playerList.getChildren().compactMap({ $0 as? MatchPlayerListPlayerView }).first(where: { $0.player.id == playerId }) {
			playerView.setDefenceBoost(active: active)
		}
	}
}
