import Foundation
import NetworkModels
import SwiftGodot

@Godot
final class MatchTurnTimerView: Control {

	@Export
	var bar: TextureProgressBar!

	private var tween: Tween?

	func startTurn() {
		bar.value = bar.maxValue
		tween = createTween()
		_ = tween?.tweenProperty(
			object: bar,
			property: "value",
			finalVal: Variant(0.0),
			duration: Double(Timings.attackPhase / 1000))

		show()
	}

	func startReinforcements(count: Int) {
		stop()

		bar.value = bar.maxValue
		tween = createTween()
		_ = tween?.tweenProperty(
			object: bar,
			property: "value",
			finalVal: Variant(0.0),
			duration: Double(Timings.reinforcementsPhase(dice: count, manual: true) / 1000))

		show()
	}

	func stop() {
		tween?.stop()
		tween = nil

		bar.value = 0

		hide()
	}

	func pause() {
		tween?.pause()
	}

	func unpause() {
		tween?.play()
	}
}
