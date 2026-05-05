import Foundation

struct MatchListDTO {
	let matches: [MatchDTO]
}

extension MatchListDTO: Codable {
	private enum CodingKeys: String, CodingKey {
		case matches
	}
}

struct MatchDTO {
	let id: String
	let name: String
	let playerCount: Int
}

extension MatchDTO: Codable {
	private enum CodingKeys: String, CodingKey {
		case id
		case name
		case playerCount
	}
}
