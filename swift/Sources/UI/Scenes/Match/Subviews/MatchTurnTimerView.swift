import Foundation
import NetworkModels
import SwiftGodot

@Godot
final class MatchTurnTimerView: Control {

	@Export
	var bar: TextureProgressBar!

	func startTurn() {
		bar.value = bar.maxValue
		_ = createTween()?.tweenProperty(object: bar, property: "value", finalVal: Variant(0.0), duration: 30)
	}
}
