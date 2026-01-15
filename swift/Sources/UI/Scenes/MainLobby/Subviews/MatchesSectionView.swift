import Foundation
import SwiftGodot
import NetworkModels

@Godot
final class MatchesSectionView: Control {
	
	private let client = WebSocketClient()

	var user: User!

	@Export
	var createMatchButton: Button!
	@Export
	var matchList: VBoxContainer!

	@Export
	var loadingIndicator: CanvasItem!

	override func _ready() {
		addChild(node: client)

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
		for mv in matchViews {
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
				ErrorManager.showError(message: "An error occurred in the HTTP request. \(error.localizedDescription)")
		}
	}

	private func createMatchView(for match: MatchDTO) {
		if let matchView = SceneLoader.load(path: "res://Screens/MainLobby/match_view.tscn") as? MatchView {
			matchView.setup(with: match)
			matchList.addChild(node: matchView)
			matchView.pressed.connect {
				self.joinTapped(match: match)
			}
		}
	}

	private func joinTapped(match: MatchDTO) {
		MatchService.joinMatch(
			matchId: match.id,
			user: user,
			webSocketClient: client,
			onJoinSuccess: handleJoinSuccess,
			onError: { error in
				GD.print("Failed to join match: \(error)")
				ErrorManager.showError(message: "Failed to join match: \(error)")
			}
		)
	}
	
	private func createMatch() {
		MatchService.createMatch(
			settings: NMMatchSettings(mapId: "", gameName: "Test match", maxPlayers: 4),
			user: user,
			webSocketClient: client,
			onCreateSuccess: handleJoinSuccess,
			onError: { error in
				GD.print("Failed to create match: \(error)")
				ErrorManager.showError(message: "Failed to create match: \(error)")
			}
		)
	}
	
	private func handleJoinSuccess(msg: NMMatchJoined) {
		GD.print("Successfully joined match with ID: \(msg.id)")
		if let lobby = SceneLoader.load(path: "res://Screens/MatchLobby/match_lobby.tscn") as? MatchLobby {
			lobby.initialize(ws: client, user: user, players: msg.players)
			changeSceneToNode(node: lobby)
		}
	}
}
