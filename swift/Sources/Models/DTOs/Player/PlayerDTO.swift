import Foundation

struct PlayerDTO {
	let id: String
	let name: String
	let level: Int
	let experience: Int
	let race: Int
	let terrain: Int
	let unlockedRaces: [Int]
	let unlockedTerrains: [Int]
}

extension PlayerDTO: Decodable {
	private enum CodingKeys: String, CodingKey {
		case id
		case name
		case level
		case experience
		case race
		case terrain
		case unlockedRaces
		case unlockedTerrains
	}
}

