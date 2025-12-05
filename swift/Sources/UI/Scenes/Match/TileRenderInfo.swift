import Foundation
import SwiftGodot

struct TileRenderInfo {
	static let sideLength: Float = 10
	static let roofHeight: Float = 4
	static let width: Float = 16
	static let rowHeight: Float = sideLength + roofHeight

	static let points: [Map.Direction: (Vector2, Vector2)] = [
		.ne: (Vector2(x: width / 2, y: 0), Vector2(x: width, y: roofHeight)),
		.e: (Vector2(x: width, y: roofHeight), Vector2(x: width, y: roofHeight + sideLength)),
		.se: (Vector2(x: width, y: roofHeight + sideLength), Vector2(x: width / 2, y: 2 * roofHeight + sideLength)),
		.sw: (Vector2(x: width / 2, y: 2 * roofHeight + sideLength), Vector2(x: 0, y: roofHeight + sideLength)),
		.w: (Vector2(x: 0, y: roofHeight + sideLength), Vector2(x: 0, y: roofHeight)),
		.nw: (Vector2(x: 0, y: roofHeight), Vector2(x: width / 2, y: 0))
	]
}
