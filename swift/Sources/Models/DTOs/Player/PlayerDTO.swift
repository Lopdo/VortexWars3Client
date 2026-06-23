import Foundation

struct PlayerDTO {
	let id: String
	let name: String
	let level: Int
	let experience: Int
	let faction: Int
	let terrain: Int
	let unlockedFactions: [Int]
	let unlockedTerrains: [Int]
}

extension PlayerDTO: Decodable {
	private enum CodingKeys: String, CodingKey {
		case id
		case name
		case level
		case experience
		case faction
		case terrain
		case unlockedFactions
		case unlockedTerrains
	}
}
