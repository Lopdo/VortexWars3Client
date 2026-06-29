import Foundation

class MatchRegion {
	let region: MapRegion
	var neighbors: [MatchRegion] = []

	var id: Int { region.id }
	var owner: MatchPlayer?

	var dice: Int {
		didSet {
			regionView.update(dice: dice)
		}
	}

	var regionView: RegionView!

	init(region: MapRegion, owner: MatchPlayer?, dice: Int) {
		self.region = region
		self.owner = owner
		self.dice = dice
	}

	func updateBorders(map: Map, owner: MatchPlayer?) {
		regionView.updateBorders(map: map, owner: owner)
		for neighbor in neighbors {
			neighbor.regionView.updateBorders(map: map, owner: neighbor.owner)
		}
	}

	func addReinforcements(dice: Int) {
		self.dice = self.dice + dice
		regionView.flashHighlight()
	}
}

extension MatchRegion: CustomDebugStringConvertible {
	public var debugDescription: String {
		"\n\(id): \(owner?.index ?? 50); dice: \(dice); neighbors: \(neighbors.map(\.id))"
	}
}
