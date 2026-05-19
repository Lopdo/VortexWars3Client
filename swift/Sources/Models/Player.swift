import Foundation

final class Player {
	let id: String
	let name: String
	let level: Int
	let experience: Int

	var race: Int
	var terrain: Int

	init(from dto: PlayerDTO) {
		self.id = dto.id
		self.name = dto.name
		self.level = dto.level
		self.experience = dto.experience

		self.race = dto.race
		self.terrain = dto.terrain
	}
}

