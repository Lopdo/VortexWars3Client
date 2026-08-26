import NetworkModels

struct MatchEliminationResult {
	let position: Int
	let gameOver: Bool
	let reason: Reason

	init(msg: NMMatchPlayerEliminated) {
		position = Int(msg.position)
		gameOver = msg.gameOver
		reason = msg.reason.reason
	}
}

extension MatchEliminationResult {

	enum Reason {
		case elimination
		case surrender
		case inactivity
		case mod
	}

}

extension NMMatchPlayerEliminated.EliminationReason {

	var reason: MatchEliminationResult.Reason {
		switch self {
			case .elimination: return .elimination
			case .inactivity: return .inactivity
			case .surrender: return .surrender
			case .mod: return .mod
		}
	}

}
