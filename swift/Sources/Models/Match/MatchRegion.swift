import Foundation

class MatchRegion {
	let region: MapRegion
	var neighbors: [MatchRegion] = []

	var owner: MatchPlayer?

	var armyCount: Int

	init(region: MapRegion, owner: MatchPlayer?, armyCount: Int) {
		self.region = region
		self.owner = owner
		self.armyCount = armyCount
	}
}
