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
			let curScene = tree.currentScene
		{
			tree.root?.addChild(node: node)
			tree.root?.removeChild(node: curScene)
			tree.currentScene = node
		} else {
			GD.print("Failed to change scene")
			ErrorManager.showError(message: "Failed to change scene")
		}
	}

}
