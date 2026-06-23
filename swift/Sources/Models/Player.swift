import Foundation

final class Player {
	let id: String
	let name: String
	let level: Int
	let experience: Int

	var faction: Int
	var terrain: Int

	var unlockedFactions: [Int]
	var unlockedTerrains: [Int]

	init(from dto: PlayerDTO) {
		id = dto.id
		name = dto.name
		level = dto.level
		experience = dto.experience

		faction = dto.faction
		terrain = dto.terrain
		unlockedFactions = dto.unlockedFactions
		unlockedTerrains = dto.unlockedTerrains
	}
}
