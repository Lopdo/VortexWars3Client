import Foundation
import NetworkModels
import SwiftGodot

@Godot
final class MatchesSectionView: Control {

	var user: User!

	@Export
	var createMatchButton: Button!
	@Export
	var matchList: VBoxContainer!

	@Export
	var loadingIndicator: CanvasItem!

	override func _ready() {
		loadingIndicator.hide()

		onRefresh()
	}

	@Callable
	func onCreateMatchButtonPressed() {
		GD.print("Create Match button pressed")

		createMatch()
	}

	@Callable
	func onRefresh() {
		let matchViews = matchList.getChildren()
		for mv in matchViews.compactMap({ $0 }) {
			matchList.removeChild(node: mv)
		}

		loadingIndicator.show()

		NetworkManager.jsonRequest(
			node: self,
			url: "/match/list",
			method: .get,
			completion: requestCompleted
		)
	}

	private func requestCompleted(result: Result<MatchListDTO, Error>) {
		loadingIndicator.hide()

		switch result {
			case .success(let matchListDTO):
				for match in matchListDTO.matches {
					createMatchView(for: match)
				}
			case .failure(let error):
				GD.print("An error occurred in the HTTP request: \(error)")
				ErrorManager.showError(
					message: "An error occurred in the HTTP request. \(error.localizedDescription)")
		}
	}

	private func createMatchView(for match: MatchDTO) {
		let matchView = CustomMatchView.loadScene()
		matchView.setup(with: match)
		matchList.addChild(node: matchView)
		matchView.pressed.connect {
			self.joinTapped(match: match)
		}
	}

	private func joinTapped(match: MatchDTO) {

		let client = WebSocketClient()
		addChild(node: client)

		MatchService.joinMatch(
			on: self,
			matchId: match.id,
			user: user,
			webSocketClient: client,
			onError: { error in
				GD.print("Failed to join match: \(error)")
				ErrorManager.showError(message: "Failed to join match: \(error)")
				self.removeChild(node: client)
			}
		)
	}

	private func createMatch() {
		let createMatchScreen = CreateCustomMatchScreen.loadScene()
		createMatchScreen.initialize(user: user)
		changeSceneToNode(node: createMatchScreen)
	}

}
