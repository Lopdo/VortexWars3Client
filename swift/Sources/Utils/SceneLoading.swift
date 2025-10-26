import Foundation
import SwiftGodot

struct SceneLoader {
	static func load(path: String) -> Node? {
		return (GD.load(path: path) as? PackedScene)?.instantiate()
	}
}

extension Node {

	func changeSceneToNode(node: Node) {
		if let tree = getTree(),
		   let curScene = tree.currentScene {
			tree.root?.addChild(node: node)
			tree.root?.removeChild(node: curScene)
			tree.currentScene = node
		} else {
			GD.print("Failed to change scene")
			ErrorManager.showError(message: "Failed to change scene")
		}
	}

}
