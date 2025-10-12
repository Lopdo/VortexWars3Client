import Foundation
import SwiftGodot

struct SceneLoader {
	static func load(path: String) -> Node? {
		return (GD.load(path: path) as? PackedScene)?.instantiate()
	}
}
