import Foundation
import NetworkModels
import SwiftGodot

@Godot
final class MatchLobbyPlayerInfoView: Control {

	private var raceIndex: Int = 1
	private var terrainIndex: Int = 1

	private var wsClient: WebSocketClient!
	private var player: Player!

	@Export
	var imgRace: TextureRect!

	@Export
	var imgTerrain: TextureRect!

	@Callable
	func onNextRace() {
		raceIndex = (raceIndex + 1) % player.unlockedRaces.count
		updateRaceTexture()
		saveRaceSelection()
	}

	@Callable
	func onPrevRace() {
		raceIndex -= 1
		if raceIndex < 0 {
			raceIndex = player.unlockedRaces.count - 1
		}
		updateRaceTexture()
		saveRaceSelection()
	}

	@Callable
	func onNextTerrain() {
		terrainIndex = (terrainIndex + 1) % player.unlockedTerrains.count

		updateTerrainTexture()
		saveTerrainSelection()
	}

	@Callable
	func onPrevTerrain() {
		terrainIndex -= 1
		if terrainIndex < 0 {
			terrainIndex = player.unlockedTerrains.count - 1
		}
		updateTerrainTexture()
		saveTerrainSelection()
	}

	func initialize(with player: Player, wsClient: WebSocketClient) {
		terrainIndex = player.terrain
		raceIndex = player.race
		self.wsClient = wsClient
		self.player = player
	}

	override func _ready() {
		updateRaceTexture()
		updateTerrainTexture()
	}

	private func updateRaceTexture() {
		let resName = "army_logo\(player.unlockedRaces[raceIndex])"
		imgRace.texture = ResourceLoader.load(path: "res://res/img/\(resName).png") as? Texture2D
	}

	private func updateTerrainTexture() {
		let resName = "terrain_\(player.unlockedTerrains[terrainIndex])"
		imgTerrain.texture = ResourceLoader.load(path: "res://res/img/\(resName).png") as? Texture2D
	}

	private func saveRaceSelection() {
		player.race = player.unlockedRaces[raceIndex]
		do {
			let msg = NMChangeRace(newRace: UInt8(player.race))
			let data = try NMEncoder.encode(msg)
			try wsClient.send(data: data)
		} catch {
			//TODO: add error handling
			GD.print("Failed to send message NMChangeRace")
		}
	}

	private func saveTerrainSelection() {
		player.terrain = player.unlockedTerrains[terrainIndex]
		do {
			let msg = NMChangeTerrain(newTerrain: UInt8(player.terrain))
			let data = try NMEncoder.encode(msg)
			try wsClient.send(data: data)
		} catch {
			//TODO: add error handling
			GD.print("Failed to send message NMChangeTerrain")
		}
	}
}
