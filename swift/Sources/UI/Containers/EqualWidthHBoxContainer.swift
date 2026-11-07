import Foundation
import SwiftGodot

@Godot(.tool)
class EqualWidthHBoxContainer: Container {

	@Export
	var separation: Float = 0 {
		didSet {
			updateMinimumSize()
			queueSort()
		}
	}

	override func _notification(code: Int, reversed: Bool) {
		switch code {
			case Container.notificationSortChildren:
				sortContainerChildren()
			default:
				break
		}
	}

	private func sortContainerChildren() {
		let controlChildren = getChildren().compactMap { $0 as? Control }
		let maxWidth = controlChildren.map { $0.getCombinedMinimumSize().x }.max() ?? 0

		var currentX: Float = 0
		for child in controlChildren {
			fitChildInRect(child: child, rect: Rect2(x: currentX, y: 0, width: maxWidth, height: getSize().y))
			currentX += maxWidth + separation  // Shift right for next item
		}
		updateMinimumSize()
	}

	override func _getMinimumSize() -> Vector2 {
		let controlChildren = getChildren().compactMap { $0 as? Control }
		guard controlChildren.count > 0 else { return .zero }

		let minSizes = controlChildren.map { $0.getCombinedMinimumSize() }
		let maxWidth = minSizes.map { $0.x }.max() ?? 0
		let maxHeight = minSizes.map { $0.y }.max() ?? 0

		GD.print(maxWidth * Float(controlChildren.count))
		return Vector2(x: maxWidth * Float(controlChildren.count) + separation * Float(controlChildren.count - 1), y: maxHeight)
	}
}
