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
		let bodyDict: [String: String] = [
			"username": lineEditUsername.text,
			"password": lineEditPassword.text,
		]

		let jsonData = try! JSONSerialization.data(withJSONObject: bodyDict)

		NetworkManager.jsonRequest(
			node: self,
			url: "/auth/login",
			method: .post,
			headers: [getAuthHeader()],
			body: jsonData,
			completion: requestCompleted
		)
	}

	private func requestCompleted(result: Result<UserDTO, Error>) {
		switch result {
			case .success(let userDTO):
				loginCompleted(userDTO: userDTO)
			case .failure(let error):
				GD.print("An error occurred in the HTTP request: \(error)")
				switch error {
					case NetworkManager.NetworkError.serverError(let code) where code == 401:
						ErrorManager.showError(message: "Invalid username or password.")
					default:
						ErrorManager.showError(message: "An error occurred in the HTTP request. \(error.localizedDescription)")
				}
		}
	}

	private func loginCompleted(userDTO: UserDTO) {
		let lobby = MainLobby.loadScene()
		lobby.initialize(user: User(from: userDTO))
		changeSceneToNode(node: lobby)
	}

	private func register() {
		let bodyDict: [String: String] = [
			"username": lineEditUsername.text,
			"password": lineEditPassword.text,
		]

		let jsonData = try! JSONSerialization.data(withJSONObject: bodyDict)

		NetworkManager.jsonRequest(
			node: self,
			url: "/auth/register",
			method: .post,
			body: jsonData,
			completion: requestCompleted
		)
	}

}
