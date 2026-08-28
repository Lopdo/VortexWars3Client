import Foundation
import SwiftGodot

extension ConfirmationPopup: SceneLoadable {
	static var pathToScene: String {
		"res://Popups/confirmation_popup.tscn"
	}
}

@Godot
final class ConfirmationPopup: Control {

	@Export
	var lblMessage: Label!

	@Export
	var btnConfirm: Button!

	func initialize(text: String, confirmText: String, onConfirm: @escaping () -> Void) {
		lblMessage.text = text
		btnConfirm.text = confirmText
		btnConfirm.pressed.connect { onConfirm() }
	}

	@Callable
	func onClose() {
		getParent()?.removeChild(node: self)
	}
}

extension ConfirmationPopup {

	static func show(on presenter: Node?, text: String, confirmText: String, onConfirm: @escaping () -> Void) {
		guard let presenter else {
			GD.print("ConfirmationPopup presenter is null")
			return
		}

		guard let gameLayer = (presenter as? MainScene)?.gameLayer else {
			GD.print("ConfirmationPopup presenter is not MainScene")
			return
		}

		let popup = ConfirmationPopup.loadScene()
		popup.initialize(text: text, confirmText: confirmText) {
			gameLayer.removeChild(node: popup)
			onConfirm()
		}

		gameLayer.addChild(node: popup)
	}

}
