import NonEmpty

struct Region {
	let id: Int
	let tiles: NonEmpty<[MapCoord]>
	let relativeTiles: NonEmpty<[RelMapCoord]>
	
	let position: (x: Int, y: Int)
	let size: (width: Int, height: Int)
	
	let center: MapCoord

	//var neighbors: Set<Int> = Set()

	init(id: Int, tiles: NonEmpty<[MapCoord]>) {
		
		self.id = id
		self.tiles = tiles
		
		self.center = Region.findArmyCenter(tiles: tiles)


		let minX = tiles.min { $0.x < $1.x }.x
		let minY = tiles.min { $0.y < $1.y }.y
		let maxX = tiles.max { $0.x < $1.x }.x
		let maxY = tiles.max { $0.y < $1.y }.y
		let swapOddEven = minY % 2 == 1
		relativeTiles = tiles.map { RelMapCoord(x: $0.x - minX, y: $0.y - minY, swapOddEven: swapOddEven) }
		position = (x: minX, y: minY)
		size = (width: maxX - minX + 1, height: maxY - minY + 1)
	}

	private static func findArmyCenter(tiles: NonEmpty<[MapCoord]>) -> MapCoord {
		// Implementation omitted for brevity
		let top = tiles.max { $0.y < $1.y }.y
		let bottom = tiles.max { $0.y > $1.y }.y
		let left = tiles.max { $0.x < $1.x }.x
		let right = tiles.max { $0.x > $1.x }.x

		let cX = (right + left) / 2
		let cY = (bottom + top) / 2

		var maxNeighbors = 0
		// prefill bestCenters with first tile
		var bestCenters: NonEmpty<[MapCoord]> = NonEmpty([tiles[0]])!
		// find all tiles that have most neighbor tiles from same region
		for tile in tiles {
			var neighborsCount = 0
			for dir in Map.Direction.allCases {
				if let neighbor = tile.getNeighborCoord(dir: dir, mapWidth: Int.max, mapHeight: Int.max) {
					if tiles.contains(neighbor) {
						neighborsCount += 1
					} else {
						//addNeighbor(neighbor)
					}
				}
			}

			// if all neighbor tiles are same, expand search
			if neighborsCount == 6 {
				for dir in Map.Direction.allCases {
					if let tile2 = tile.getNeighborCoord(dir: dir, mapWidth: Int.max, mapHeight: Int.max) {
						for dir2 in Map.Direction.allCases {
							if let neighbor2 = tile2.getNeighborCoord(dir: dir2, mapWidth: Int.max, mapHeight: Int.max),
							   tiles.contains(neighbor2) {
								neighborsCount += 1
							}
						}
					}
				}
			}

			if neighborsCount > maxNeighbors {
				bestCenters = NonEmpty([tile])!
				maxNeighbors = neighborsCount
			} else if neighborsCount == maxNeighbors {
				bestCenters.append(tile)
			}
		}

		// find most central tile
		return bestCenters.max { abs(cX - $0.x) + abs(cY - $0.y) < abs(cX - $1.x) + abs(cY - $1.y) }
	}


}

