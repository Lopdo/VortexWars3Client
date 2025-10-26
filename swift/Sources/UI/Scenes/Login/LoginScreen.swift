import Foundation
import SwiftGodot

@Godot
final class LoginScreen: Node {

	@Export
	var lineEditUsername: LineEdit!

	@Export
	var lineEditPassword: LineEdit!

	@Callable
	func onLoginPressed() {
		GD.print("Login pressed: \(lineEditUsername.text), \(lineEditPassword.text)")
		login()
	}

	@Callable
	func onRegisterPressed() {
		GD.print("Register pressed: \(lineEditUsername.text), \(lineEditPassword.text)")
		register()
	}

	private func getAuthHeader() -> String {
		let token = "\(lineEditUsername.text):\(lineEditPassword.text)"
		return "Authorization: Basic " + token.base64Encoded.string!
	}

	private func login() {
		let httpRequest = HTTPRequest()
		addChild(node: httpRequest)
		httpRequest.requestCompleted.connect { result, responseCode, headers, body in
			self.httpRequestCompleted(result: result, responseCode: responseCode, headers: headers, body: body)
		}

		let authHeader = getAuthHeader()
		GD.print("Auth Header: \(authHeader)")

		let error = httpRequest.request(url: "http://127.0.0.1:8080/auth/login", customHeaders: [authHeader], method: .post)
		if error != .ok {
			GD.print("An error occurred in the HTTP request.")
			ErrorManager.showError(message: "An error occurred in the HTTP request.")
		}
	}

	private func register() {
		let httpRequest = HTTPRequest()
		addChild(node: httpRequest)
		httpRequest.requestCompleted.connect { result, responseCode, headers, body in
			self.httpRequestCompleted(result: result, responseCode: responseCode, headers: headers, body: body)
		}

		let bodyDict: [String: String] = [
			"username": lineEditUsername.text,
			"password": lineEditPassword.text
		]

		let jsonData = try! JSONSerialization.data(withJSONObject: bodyDict)
		//let jsonString = GString(String(data: jsonData, encoding: .utf8)!)

		let error = httpRequest.request(url: "http://127.0.0.1:8080/auth/register", customHeaders: ["Content-Type: application/json"], method: .post, requestData: String(data: jsonData, encoding: .utf8)!)
		if error != .ok {
			GD.print("An error occurred in the HTTP request.")
			ErrorManager.showError(message: "An error occurred in the HTTP request.")
		}
	}

	private func httpRequestCompleted(result: Int64, responseCode: Int64, headers: PackedStringArray, body: PackedByteArray) {
		if result != 0 {
			ErrorManager.showError(message: "An error occurred in the HTTP request. \(result)")
			return
		}

		GD.print("Response Body: \(body.getStringFromUtf8())")
		if responseCode == 500 {
			ErrorManager.showHTTPError(body: body)
		} else if responseCode == 200 {
			let data = Data(body.asBytes())
				if let userDTO = try? JSONDecoder().decode(UserDTO.self, from: data) {
					if let lobby = SceneLoader.load(path: "res://Screens/MainLobby/main_lobby.tscn") as? MainLobby {
						lobby.initialize(user: User(from: userDTO))
						changeSceneToNode(node: lobby)
					} else {
						GD.print("Failed to load MainLobby scene")
						ErrorManager.showError(message: "Failed to load MainLobby scene")
					}
				} else {
					ErrorManager.showError(message: "Failed to parse login response")
				}
		} else {
			ErrorManager.showError(message: "An error occurred in the HTTP request. \(responseCode)")
		}
	}

}
