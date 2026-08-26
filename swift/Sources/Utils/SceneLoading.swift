import Foundation
import SwiftGodot

struct SceneLoader {
	static func load(path: String) -> Node? {
		return (GD.load(path: path) as? PackedScene)?.instantiate()
	}
}

protocol SceneLoadable {
	static var pathToScene: String { get }
}

extension SceneLoadable {

	static func loadScene() -> Self {
		if let scene = SceneLoader.load(path: pathToScene) as? Self {
			return scene
		} else {
			fatalError("Failed to load \(Self.self)")
		}
	}
}

extension Node {

	func changeSceneToNode(node: Node) {
		if let tree = getTree(),
			let mainScene = tree.currentScene as? MainScene
		{
			for child in mainScene.gameLayer.getChildren().compactMap({ $0 }) {
				mainScene.gameLayer.removeChild(node: child)
			}

			mainScene.gameLayer.addChild(node: node)
		} else {
			GD.print("Failed to change scene")
			//GD.print("tree: \(getTree()); currentScene: \(getTree()?.currentScene)")
			ErrorManager.showError(message: "Failed to change scene")
		}
	}

}
