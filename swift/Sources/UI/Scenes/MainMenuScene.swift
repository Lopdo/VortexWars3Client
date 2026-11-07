import Foundation
import SwiftGodot

extension MainMenuScene: SceneLoadable {
	static var pathToScene: String {
		"res://Screens/main_menu.tscn"
	}
}

@Godot
final class MainMenuScene: CanvasLayer {

	@Export
	var contentContainer: Container!

	private var user: User!

	override func _ready() {
	}

	func initialize(user: User) {
		self.user = user

		let customLobby = CustomLobby.loadScene()
		customLobby.initialize(user: user)
		contentContainer.addChild(node: customLobby)
	}

	private func swapContent(newContent: Node) {
		contentContainer.getChildren().compactMap { $0 }.forEach { contentContainer.removeChild(node: $0) }
		contentContainer.addChild(node: newContent)
	}

	@Callable
	func onRankedPressed() {
		let rankedLobby = RankedLobby.loadScene()
		rankedLobby.initialize(user: user)
		swapContent(newContent: rankedLobby)
	}

	@Callable
	func onCustomPressed() {
		let customLobby = CustomLobby.loadScene()
		customLobby.initialize(user: user)
		swapContent(newContent: customLobby)
	}
}
