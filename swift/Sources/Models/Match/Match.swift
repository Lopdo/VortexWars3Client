import Foundation
import NetworkModels

class Match {
	let map: Map
	//let regions: [MatchRegion]
	let players: [MatchPlayer]

	init(mapData: NMMatchMapData, players: [MatchPlayer]) {
		map = Map(mapData: mapData, players: players)

		self.players = players
	}

	func owner(at coord: MapCoord) -> MatchPlayer? {
		let tile = map.tile(at: coord)

		if tile == 0 {
			return nil
		}

		return map.regions[tile - 1].owner
	}

}
