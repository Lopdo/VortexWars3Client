import Foundation
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

	let regions: [Region]

	init(tiles: [Int], width: Int, height: Int) {
		self.tiles = tiles
		self.width = width
		self.height = height
		self.regions = Map.createRegions(from: tiles, width: width, height: height)
	}
	
	private static func createRegions(from tiles: [Int], width: Int, height: Int) -> [Region] {
		var regions: [Region] = []
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
						if let neighbor = current.getNeighborCoord(dir: dir, mapWidth: width, mapHeight: height),
						   tiles[neighbor.y * width + neighbor.x] == tileValue,
						   !visited.contains(neighbor) {
							toVisit.append(neighbor)
						}
					}
				}

				if let nonEmptyTiles = NonEmpty(rawValue: regionTiles) {
					let region = Region(id: tileValue, tiles: nonEmptyTiles)
					regions.append(region)
				}
			}
		}

		return regions
	}

	func tile(at coord: MapCoord) -> Int {
		assert(coord.x >= 0 || coord.x < width || coord.y >= 0 || coord.y < height, "Attempting to access tile outside of the bounds: \(coord)")

		return tiles[coord.y * width + coord.x]
	}
}
