import Foundation

struct UserDTO {
	let id: UUID
	let username: String
	let sessionToken: UUID

	let player: PlayerDTO
}

extension UserDTO: Decodable {
	enum CodingKeys: String, CodingKey {
		case id
		case username
		case sessionToken

		case player
	}
}