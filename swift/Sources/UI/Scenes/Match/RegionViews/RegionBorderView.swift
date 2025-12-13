import Foundation
import SwiftGodot

@Godot
class RegionBorderView: Node2D {
	
	var region: MatchRegion!
	var map: Map!

	var borderLine: Line2D!
	private var externalBorders: [Line2D] = []
	
	override func _ready() {
		borderLine = createRegionBorder(map: map)
		addChild(node: borderLine)
	}

	func updateBorders(match: Match) {
		guard let owner = region.owner else {
			return
		}

		externalBorders.forEach { removeChild(node: $0) }
		externalBorders.removeAll()

		var segments = getExternalBorderSegments(match: match)
		var currentSegment = segments.removeFirst()
		var linesPoints: [[Vector2]] = []
		var linePoints: [Vector2] = []
		linePoints.append(currentSegment.start)

		repeat {
			var foundNext = false
			for (index, segment) in segments.enumerated() {
				if segment.start == currentSegment.end {
					linePoints.append(segment.start)
					segments.remove(at: index)
					currentSegment = segment
					foundNext = true
					break
				} 
			}
			if !foundNext {
				//finish current line and start a new one
				linePoints.append(currentSegment.end)
				linesPoints.append(linePoints)
				if !segments.isEmpty {
					currentSegment = segments.removeFirst()
					linePoints = []
					linePoints.append(currentSegment.start)
				}
			}
		} while !segments.isEmpty

		linePoints.append(currentSegment.end)
		linesPoints.append(linePoints)

        //check if we can merge some lines
		var mergedLines: [[Vector2]] = []
		for points in linesPoints {
			var merged = false
			for (index, var existingLine) in mergedLines.enumerated() {
				if existingLine.last == points.first {
					existingLine.append(contentsOf: points.dropFirst())
					mergedLines[index] = existingLine
					merged = true
					break
				} else if existingLine.first == points.last {
					var newLine = points
					newLine.append(contentsOf: existingLine.dropFirst())
					mergedLines[index] = newLine
					merged = true
					break
				}
			}
			if !merged {
				mergedLines.append(points)
			}
		} 

		for points in mergedLines {
			let line = Line2D()
			line.endCapMode = .box
			line.beginCapMode = .box
			line.width = 6
			line.defaultColor = owner.borderColor
			for point in points {
				line.addPoint(position: point)
			}
			addChild(node: line)
			externalBorders.append(line)
		}
	}

	private func getExternalBorderSegments(match: Match) -> [BorderSegment] {
		var segments: [BorderSegment] = []
		
		for tile in region.region.tiles {
			let relPosX = Float(tile.x - region.region.position.x) * TileRenderInfo.width
			let relPosY = Float(tile.y - region.region.position.y) * (TileRenderInfo.sideLength + TileRenderInfo.roofHeight)
			let xOffset = (tile.y % 2 == 1) ? TileRenderInfo.width / 2 : 0
			let cornerVector = Vector2(x: relPosX + xOffset, y: relPosY)
			
			for dir in Map.Direction.allCases {
				let neighborCoord = tile.getNeighborCoord(dir: dir, mapWidth: match.map.width, mapHeight: match.map.height)
				
				if neighborCoord == nil || match.map.tile(at: neighborCoord!) == 0 || 
				   (!region.region.tiles.contains(neighborCoord!) && match.owner(at: neighborCoord!) != region.owner) {
					let startPoint = cornerVector + TileRenderInfo.points[dir]!.0
					let endPoint = cornerVector + TileRenderInfo.points[dir]!.1
					segments.append(BorderSegment(start: startPoint, end: endPoint))
				}
			}
		}
		
		return segments
	}

	private func createRegionBorder(map: Map) -> Line2D {
		let line = Line2D()
		var segments = getBorderSegments(map: map)
		//sort segments to form continuous lines
		var currentSegment = segments.removeFirst()
		line.addPoint(position: currentSegment.start)

		repeat {
			for (index, segment) in segments.enumerated() {
				if segment.start == currentSegment.end {
					line.addPoint(position: segment.start)
					segments.remove(at: index)
					currentSegment = segment
					break
				} else if segment.end == currentSegment.end {
					line.addPoint(position: segment.end)
					segments.remove(at: index)
					currentSegment = segment.reversed()
					break
				}
			}
		} while !segments.isEmpty
		
		line.addPoint(position: currentSegment.end)
		line.defaultColor = region.owner?.borderColor ?? Color.lightGray
		line.width = 2

		return line
	}

	private func getBorderSegments(map: Map) -> [BorderSegment] {
		var segments: [BorderSegment] = []
		
		for tile in region.region.tiles {
			let relPosX = Float(tile.x - region.region.position.x) * TileRenderInfo.width
			let relPosY = Float(tile.y - region.region.position.y) * (TileRenderInfo.sideLength + TileRenderInfo.roofHeight)
			let xOffset = (tile.y % 2 == 1) ? TileRenderInfo.width / 2 : 0
			let cornerVector = Vector2(x: relPosX + xOffset, y: relPosY)
			
			for dir in Map.Direction.allCases {
				let neighborCoord = tile.getNeighborCoord(dir: dir, mapWidth: map.width, mapHeight: map.height)
				
				if neighborCoord == nil || !region.region.tiles.contains(neighborCoord!) {
					let startPoint = cornerVector + TileRenderInfo.points[dir]!.0
					let endPoint = cornerVector + TileRenderInfo.points[dir]!.1
					segments.append(BorderSegment(start: startPoint, end: endPoint))
				}
			}
		}
		
		return segments
	}
}


fileprivate struct BorderSegment {
	let start: Vector2
	let end: Vector2

	func reversed() -> BorderSegment {
		return BorderSegment(start: end, end: start)
	}
}
