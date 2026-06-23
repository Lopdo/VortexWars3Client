import Foundation
import NetworkModels
import NonEmpty

struct Map {

	enum Direction: CaseIterable {
		case ne
		case e
		case se
		case sw
		case w
		case nw
	}

	private let tiles: [Int]
	let width: Int
	let height: Int

	let regions: [MatchRegion]

	init(mapData: NMMatchMapData, players: [MatchPlayer]) {
		self.tiles = mapData.tiles.map { Int($0) }
		self.width = Int(mapData.width)
		self.height = Int(mapData.height)

		let mapRegions = Map.createRegions(from: tiles, width: width, height: height)

		regions = mapRegions.map { mapRegion in
			let mapDataRegion = mapData.regions.first(where: { $0.id == mapRegion.id })
			let owner = players.first(where: { UInt8($0.index) == mapDataRegion?.ownerIndex })
			return MatchRegion(
				region: mapRegion, owner: owner, dice: Int(mapDataRegion?.dice ?? 0))
		}
		.sorted(by: { $0.region.id < $1.region.id })

		for region in regions {
			if let mapDataRegion = mapData.regions.first(where: { $0.id == region.region.id }) {
				region.neighbors = regions.filter {
					mapDataRegion.neighbors.contains(UInt8($0.region.id))
				}
			}
		}
	}

	private static func createRegions(from tiles: [Int], width: Int, height: Int) -> [MapRegion] {
		var regions: [MapRegion] = []
		var visited: Set<MapCoord> = Set()

		for y in 0..<height {
			for x in 0..<width {
				let coord = MapCoord(x: x, y: y)
				if visited.contains(coord) {
					continue
				}

				let tileValue = tiles[y * width + x]

				if tileValue == 0 {
					visited.insert(coord)
					continue
				}

				var regionTiles: [MapCoord] = []
				var toVisit: [MapCoord] = [coord]

				while !toVisit.isEmpty {
					let current = toVisit.removeLast()
					if visited.contains(current) {
						continue
					}
					visited.insert(current)
					regionTiles.append(current)

					for dir in Direction.allCases {
						if let neighbor = current.getNeighborCoord(
							dir: dir, mapWidth: width, mapHeight: height),
							tiles[neighbor.y * width + neighbor.x] == tileValue,
							!visited.contains(neighbor)
						{
							toVisit.append(neighbor)
						}
					}
				}

				if let nonEmptyTiles = NonEmpty(rawValue: regionTiles) {
					let region = MapRegion(id: tileValue, tiles: nonEmptyTiles)
					regions.append(region)
				}
			}
		}

		return regions
	}

	func owner(at coord: MapCoord) -> MatchPlayer? {
		let tile = tile(at: coord)

		if tile == 0 {
			return nil
		}

		return regions[tile - 1].owner
	}

	func tile(at coord: MapCoord) -> Int {
		assert(
			coord.x >= 0 || coord.x < width || coord.y >= 0 || coord.y < height,
			"Attempting to access tile outside of the bounds: \(coord)")

		return tiles[coord.y * width + coord.x]
	}
}
