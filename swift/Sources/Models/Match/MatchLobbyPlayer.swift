import NetworkModels
import SwiftGodot

struct MatchLobbyPlayer {
	let id: String
	let name: String

	var race: Int
	var terrain: Int

	var isReady: Bool
	var isCook: Bool

	init(from player: NMMatchLobbyPlayer) {
		id = player.id
		name = player.name
		race = Int(player.race)
		terrain = 0

		isReady = false
		isCook = player.isCook
	}
}
