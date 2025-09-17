import Foundation
import SwiftGodot

@Godot 
// @MainActor
final class ErrorPopup: Control {

	static var canvasLayer: CanvasLayer!

	@Export
	var lblMessage: RichTextLabel!

	@Export
	var btnOkay: Button!

	override func _ready() {
		hide()
		
		btnOkay.pressed.connect {	
			self.onOkay()
		}
	}

	func showError(message: String) {
		lblMessage.text = message
		show()
	}

	func showHTTPError(body: PackedByteArray) {
		if let jsonString = String(data: Data(body), encoding: .utf8) {
			if let data = jsonString.data(using: .utf8) {
				if let errorResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
					if let message = errorResponse["message"] as? String,
					   let code = errorResponse["code"] as? Int {
						showError(message: "\(message) - \(code)")
					} else {
						showError(message: "Invalid error response format")
					}
				} else {
					showError(message: "Failed to parse JSON")
				}
			} else {
				showError(message: "Failed to convert string to data")
			}
		} else {
			showError(message: "Failed to decode body as UTF-8 string")
		}
	}
	
	func onOkay() {	
		hide()
	}

}