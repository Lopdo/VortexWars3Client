import Foundation
import SwiftGodot

extension MatchPlayerListPlayerView: SceneLoadable {
	static var pathToScene: String {
		"res://Screens/Match/match_player.tscn"
	}
}

@Godot
final class MatchPlayerListPlayerView: Control {

	@Export
	var lblName: Label!

	@Export
	var lblCurrent: Label!

	@Export
	var lblStrength: Label!

	@Export
	var btnDefenceBoost: Button!

	@Export
	var btnAttackBoost: Button!

	@Export
	var disconnectedIndicator: CanvasItem!

	@Export
	var colorRect: ColorRect!

	@Export
	var viewDetails: CanvasItem!

	@Export
	var viewBoosts: CanvasItem!

	@Export
	var viewDefeated: CanvasItem!

	unowned var player: MatchPlayer!
	unowned var match: Match!

	func initialize(player: MatchPlayer, isMe: Bool, match: Match) {
		self.player = player
		lblName.text = player.id + (isMe ? "*" : "")
		self.match = match
		if !isMe {
			btnAttackBoost.disabled = true
			btnDefenceBoost.disabled = true
		}
		colorRect.color = player.color
		viewDefeated.hide()
		if !match.settings.boosterEnabled {
			viewBoosts.hide()
		}
	}

	func set(current: Bool) {
		lblCurrent.text = current ? "X" : "_"
	}

	func set(disconnected: Bool) {
		if disconnected {
			disconnectedIndicator.show()
		} else {
			disconnectedIndicator.hide()
		}
	}

	func markAsDefeated() {
		viewDefeated.show()
		viewDetails.hide()
	}

	func set(strength: Int) {
		lblStrength.text = "[\(strength)]"
	}

	func disableAttackBoosts() {
		btnAttackBoost.visible = false
	}

	func disableDefenceBoosts() {
		btnDefenceBoost.visible = false
	}

	func setAttackBoost(count: Int) {
		btnAttackBoost.text = "A \(count)"
		btnAttackBoost.disabled = btnAttackBoost.disabled || count == 0
	}

	func setDefenceBoost(count: Int) {
		btnDefenceBoost.text = "D \(count)"
		btnDefenceBoost.disabled = btnDefenceBoost.disabled || count == 0
	}

	func setAttackBoost(active: Bool) {
		//btnAttackBoost.flat = active ? true : false
	}

	func setDefenceBoost(active: Bool) {
		//btnDefenceBoost.flat = active ? true : false
	}

	@Callable
	func onDefenceBoostTapped() {
		match.activateDefenceBoost()
	}

	@Callable
	func onAttackBoostTapped() {
		match.activateAttackBoost()
	}
}
