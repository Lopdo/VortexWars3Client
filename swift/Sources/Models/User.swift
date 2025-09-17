import Foundation

struct User {
	let id: String
	let username: String
	let sessionToken: String

	let player: Player

	init(from dto: UserDTO) {
		self.id = dto.id.uuidString
		self.username = dto.username
		self.sessionToken = dto.sessionToken.uuidString
		self.player = Player(from: dto.player)
	}
}