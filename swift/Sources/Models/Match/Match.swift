import Foundation

class Match {
	let map: Map
	let regions: [MatchRegion]
	let players: [MatchPlayer]

	init(map: Map, players: [MatchPlayer]) {
		self.map = map
		self.regions = map.regions.map { MatchRegion(region: $0) }
		self.players = players
	}

	func owner(at coord: MapCoord) -> MatchPlayer? {
		let tile = map.tile(at: coord)

		if tile == 0 {
			return nil
		}

		return regions[tile - 1].owner
	}

}
