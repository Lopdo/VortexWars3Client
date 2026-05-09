import Foundation

class MatchRegion {
	let region: MapRegion
	var neighbors: [MatchRegion] = []

	var owner: MatchPlayer?

	var armySize: Int

	var regionView: RegionView!

	init(region: MapRegion, owner: MatchPlayer?, armySize: Int) {
		self.region = region
		self.owner = owner
		self.armySize = armySize
	}
}
