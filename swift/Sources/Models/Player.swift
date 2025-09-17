import Foundation

struct Player {
	let id: String
	let name: String
	let level: Int
	let experience: Int

	init(from dto: PlayerDTO) {
		self.id = dto.id
		self.name = dto.name
		self.level = dto.level
		self.experience = dto.experience
	}
}