import Foundation

final class Player {
	let id: String
	let name: String
	let level: Int
	let experience: Int

	var race: Int
	var terrain: Int

	var unlockedRaces: [Int]
	var unlockedTerrains: [Int]

	init(from dto: PlayerDTO) {
		id = dto.id
		name = dto.name
		level = dto.level
		experience = dto.experience

		race = dto.race
		terrain = dto.terrain
		unlockedRaces = dto.unlockedRaces
		unlockedTerrains = dto.unlockedTerrains
	}
}

