import Foundation

class MatchRegion {
	let region: MapRegion
	var neighbors: [MatchRegion] = []

	var id: Int { region.id }
	var owner: MatchPlayer?

	var armySize: Int {
		didSet {
			regionView.update(armySize: armySize)
		}
	}

	var regionView: RegionView!

	init(region: MapRegion, owner: MatchPlayer?, armySize: Int) {
		self.region = region
		self.owner = owner
		self.armySize = armySize
	}

	func updateBorders(map: Map, owner: MatchPlayer?) {
		regionView.updateBorders(map: map, owner: owner)
		for neighbor in neighbors {
			neighbor.regionView.updateBorders(map: map, owner: neighbor.owner)
		}
	}
}

extension MatchRegion: CustomDebugStringConvertible {
	public var debugDescription: String {
		"\n\(id): \(owner?.index ?? 50); army: \(armySize); neighbors: \(neighbors.map(\.id))"
	}
}
