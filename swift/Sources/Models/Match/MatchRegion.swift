import Foundation

class MatchRegion {
	let region: Region
	var owner: MatchPlayer?

	var armyCount: Int

	init(region: Region) {
		self.region = region
		self.armyCount = 0
	}
}
