struct MapCoord {
	let x: Int
	let y: Int

	func getNeighborCoord(dir: Map.Direction, mapWidth: Int, mapHeight: Int) -> MapCoord? {
		var nx: Int = x
		var ny: Int = y
		switch(dir) {
			case .ne: 
				nx += (ny % 2 == 1) ? 1 : 0
				ny -= 1
			case .e:
				nx += 1
			case .se:
				nx += (ny % 2 == 1) ? 1 : 0
				ny += 1
			case .sw:
				nx -= (ny % 2 == 1) ? 0 : 1
				ny += 1
			case .w:
				nx -= 1
			case .nw:
				nx -= (ny % 2 == 1) ? 0 : 1
				ny -= 1
		}

		if nx < 0 || nx >= mapWidth || ny < 0 || ny >= mapHeight {
			return nil
		} else { 
			return MapCoord(x: nx, y: ny)
		}
	}

	static func getNeighborCoord(from coord: MapCoord, dir: Map.Direction, mapWidth: Int, mapHeight: Int) -> MapCoord? {
		var nx: Int = coord.x
		var ny: Int = coord.y
		switch(dir) {
			case .ne: 
				nx += (ny % 2 == 1) ? 1 : 0
				ny -= 1
			case .e:
				nx += 1
			case .se:
				nx += (ny % 2 == 1) ? 1 : 0
				ny += 1
			case .sw:
				nx -= (ny % 2 == 1) ? 0 : 1
				ny += 1
			case .w:
				nx -= 1
			case .nw:
				nx -= (ny % 2 == 1) ? 0 : 1
				ny -= 1
		}

		if nx < 0 || nx >= mapWidth || ny < 0 || ny >= mapHeight {
			return nil
		} else { 
			return MapCoord(x: nx, y: ny)
		}
	}
}

extension MapCoord: Hashable {}

extension MapCoord: CustomDebugStringConvertible {
	var debugDescription: String {
		"<\(x),\(y)>"
	}
}
