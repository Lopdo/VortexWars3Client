import Foundation
import SwiftGodot

extension PlayerEliminatedPopup: SceneLoadable {
	static var pathToScene: String {
		"res://Screens/Match/Popups/player_eliminated_popup.tscn"
	}
}

@Godot
final class PlayerEliminatedPopup: Control {

	@Export
	var lblTitle: Label!

	@Export
	var lblPosition: Label!

	@Export
	var btnQuit: Button!

	@Export
	var btnClose: Button!

	var onQuitCallback: (() -> Void)!

	func initialize(result: MatchEliminationResult) {
		if result.position == 1 {
			lblTitle.text = "You won!"
			lblPosition.text = "You defeated all enemies"
		} else {
			switch result.reason {
				case .elimination:
					lblTitle.text = "You were defeated"
				case .surrender:
					lblTitle.text = "You surrendered"
				case .inactivity:
					lblTitle.text = "You were kicked for inactivity"
				case .mod:
					lblTitle.text = "You have been kicked by moderator"
			}
			lblPosition.text = "You finished in \(result.position). place"
		}

		if result.gameOver {
			btnClose.hide()
		}
	}

	@Callable
	func onClose() {
		getParent()?.removeChild(node: self)
	}

	@Callable
	func onQuit() {
		onQuitCallback()
	}
}
