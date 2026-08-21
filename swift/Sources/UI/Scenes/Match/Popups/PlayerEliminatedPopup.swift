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

	func initialize(position: Int, gameOver: Bool) {
		if position == 1 {
			lblTitle.text = "You won!"
			lblPosition.text = "You defeated all enemies"
		} else {
			lblTitle.text = "You were defeated"
			lblPosition.text = "You finished in \(position). place"
		}

		if gameOver {
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
