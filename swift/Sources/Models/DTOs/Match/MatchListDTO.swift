import Foundation

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
	let name: String
	let playerCount: Int
}

extension MatchDTO: Decodable {
	private enum CodingKeys: String, CodingKey {
		case id
		case name
		case playerCount
	}
}

struct CurrentMatchDTO: Decodable {
	let match: MatchDTO?
}
