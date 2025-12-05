struct RelMapCoord {
	let x: Int
	let y: Int
	let swapOddEven: Bool

	func getNeighborCoord(dir: Map.Direction, mapWidth: Int, mapHeight: Int) -> MapCoord? {
		var nx: Int = x
		var ny: Int = y
		let odd = (swapOddEven ? (ny % 2 == 0) : (ny % 2 == 1))

		switch(dir) {
			case .ne: 
				nx += odd ? 1 : 0
				ny -= 1
			case .e:
				nx += 1
			case .se:
				nx += odd ? 1 : 0
				ny += 1
			case .sw:
				nx -= odd ? 0 : 1
				ny += 1
			case .w:
				nx -= 1
			case .nw:
				nx -= odd ? 0 : 1
				ny -= 1
		}

		if nx < 0 || nx >= mapWidth || ny < 0 || ny >= mapHeight {
			return nil
		} else { 
			return MapCoord(x: nx, y: ny)
		}
	}

	static func getNeighborCoord(from coord: RelMapCoord, dir: Map.Direction, mapWidth: Int, mapHeight: Int) -> MapCoord? {
		var nx: Int = coord.x
		var ny: Int = coord.y
		let odd = (coord.swapOddEven ? (ny % 2 == 0) : (ny % 2 == 1))
		
		switch(dir) {
			case .ne: 
				nx += odd ? 1 : 0
				ny -= 1
			case .e:
				nx += 1
			case .se:
				nx += odd ? 1 : 0
				ny += 1
			case .sw:
				nx -= odd ? 0 : 1
				ny += 1
			case .w:
				nx -= 1
			case .nw:
				nx -= odd ? 0 : 1
				ny -= 1
		}

		if nx < 0 || nx >= mapWidth || ny < 0 || ny >= mapHeight {
			return nil
		} else { 
			return MapCoord(x: nx, y: ny)
		}
	}
}

extension RelMapCoord: Hashable {}

extension RelMapCoord: CustomDebugStringConvertible {
	var debugDescription: String {
		"<\(x)\(swapOddEven ? "*" : ""),\(y)>"
	}
}
