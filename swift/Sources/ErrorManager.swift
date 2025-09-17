import Foundation
import SwiftGodot

class ErrorManager {
	
	private static func createPopup() -> ErrorPopup? {
		guard let errorScene = GD.load(path: "res://Popups/ErrorPopup.tscn") as? PackedScene,
			let popup = errorScene.instantiate() as? ErrorPopup else {
			GD.print("Failed to load ErrorPopup scene")
			return nil
		}
		ErrorPopup.canvasLayer.addChild(node: popup)
		return popup
	}

	static func showError(message: String) {
		// log the error somewhere (analytics) as well
		guard let popup = createPopup() else {
			return
		}
		popup.showError(message: message)
	}
	
	static func showHTTPError(body: PackedByteArray) {
		guard let popup = createPopup() else {
			return
		}
		popup.showHTTPError(body: body)
	}
}