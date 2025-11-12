import NetworkModels

struct MatchPlayer {
	let id: String
	let name: String

	var isReady: Bool
	var isCook: Bool

	init(from player: NMMatchPlayer) {
		id = player.id
		name = player.name

		isReady = false
		isCook = player.isCook
	}
}
