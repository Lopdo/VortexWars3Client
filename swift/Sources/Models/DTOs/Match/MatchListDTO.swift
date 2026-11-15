import Foundation
import NetworkModels

struct MatchListDTO {
	let matches: [MatchDTO]
}

extension MatchListDTO: Decodable {
	private enum CodingKeys: String, CodingKey {
		case matches
	}
}

struct MatchDTO {
	let id: String
	let settings: MatchSettingsDTO
	let playerCount: Int
}

extension MatchDTO: Decodable {
	private enum CodingKeys: String, CodingKey {
		case id
		case settings
		case playerCount
	}
}

struct MatchSettingsDTO {
	let mapType: NMMatchSettings.MapType
	let matchName: String
	let maxPlayers: Int
	let startCondition: NMMatchSettings.StartCondition
	let combatRule: NMMatchSettings.CombatRule
	let reinforcementsRule: NMMatchSettings.ReinforcementsRule
	let boosterEnabled: Bool
}

extension MatchSettingsDTO: Decodable {
	private enum CodingKeys: String, CodingKey {
		case mapType
		case matchName
		case maxPlayers
		case startCondition
		case combatRule
		case reinforcementsRule
		case boosterEnabled
	}
}

struct CurrentMatchDTO: Decodable {
	let match: MatchDTO?
}
