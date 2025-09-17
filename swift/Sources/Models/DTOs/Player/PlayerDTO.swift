import Foundation

struct PlayerDTO {
	let id: String
	let name: String
	let level: Int
	let experience: Int
}

extension PlayerDTO: Decodable {
	private enum CodingKeys: String, CodingKey {
		case id
		case name
		case level
		case experience
	}
}