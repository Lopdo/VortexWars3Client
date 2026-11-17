import Foundation
import SwiftGodot

extension ProfileScreen: SceneLoadable {
	static var pathToScene: String {
		"res://Screens/Profile/profile_screen.tscn"
	}
}

@Godot
final class ProfileScreen: Control {

	@Export(.nodeType)
	private var viewPlayerInfo: ProfilePlayerInfoView!

	@Export(.nodeType)
	private var viewPlayerStats: ProfilePlayerStatsView!

	//TODO: hide for steam users?
	@Export(.nodeType)
	private var btnLogot: Button!

	func initialize(user: User) {
		//self.user = user
		viewPlayerInfo.initialize(player: user.player)
	}

	@Callable
	private func onFriendsTapped() {
		//TODO:
	}

	@Callable
	private func onReplaysTapped() {
		//TODO:
	}

	@Callable
	private func onAchievementsTapped() {
		//TODO:
	}

	@Callable
	private func onArmoryTapped() {
		//TODO:
	}

	@Callable
	private func onLogoutTapped() {
		//TODO: disconnect from chat websockets? will be automatic?

		let loginScreen = LoginScreen.loadScene()
		changeSceneToNode(node: loginScreen)
	}
}
