import Foundation
import SwiftGodot

class MatchPlayer {
	let id: UUID
	let index: Int

	var color: Color {
		MatchPlayer.colors[index]
	}
	var borderColor: Color {
		MatchPlayer.borderColors[index]
	}

	init(index: Int) {
		self.index = index
		self.id = UUID()
	}
}

extension MatchPlayer: Equatable {
	static func ==(lhs: MatchPlayer, rhs: MatchPlayer) -> Bool {
		return lhs.id == rhs.id
	}
}

extension MatchPlayer {
	static let colors = [Color(code: "#C70000"), Color(code: "#4353FF"), Color(code: "#C9C700"), Color(code: "#019327"), Color(code: "#B4065D"), Color(code: "#FF7F00"), Color(code: "#009597"), Color(code: "#934200")]
	static let borderColors = [Color(code: "#FF3C3C"), Color(code: "#5080FF"), Color(code: "#FFFC17"), Color(code: "#00ff42"), Color(code: "#F660AB"), Color(code: "#FFA200"), Color(code: "#00FCFF"), Color(code: "#A9651C")]
	//static let nameColors:Array = new Array(0xFFE3C3C, 0x4353FF, 0xFFFC17, 0x019327, 0xF660AB, 0xFF7F00, 0x00FCFF, 0xA9651C)
}
		
