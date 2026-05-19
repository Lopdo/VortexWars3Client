import Foundation
import NetworkModels
import SwiftGodot

@Godot
final class MatchLobbyPlayerInfoView: Control {

	private var race: Int = 1
	private let raceCount: Int = 3
	private var terrain: Int = 1
	private let terrainCount: Int = 2

	private var wsClient: WebSocketClient!
	private var player: Player!

	@Export
	var imgRace: TextureRect!

	@Export
	var imgTerrain: TextureRect!

	@Callable
	func onNextRace() {
		race = (race + 1) % raceCount
		updateRaceTexture()
		saveRaceSelection()
	}

	@Callable
	func onPrevRace() {
		race -= 1
		if race < 0 {
			race = raceCount - 1
		}
		updateRaceTexture()
		saveRaceSelection()
	}

	@Callable
	func onNextTerrain() {
		terrain = (terrain + 1) % terrainCount
		updateTerrainTexture()
		saveTerrainSelection()
	}

	@Callable
	func onPrevTerrain() {
		terrain -= 1
		if terrain < 0 {
			terrain = terrainCount - 1
		}
		updateTerrainTexture()
		saveTerrainSelection()
	}

	func initialize(with player: Player, wsClient: WebSocketClient) {
		terrain = player.terrain
		race = player.race
		self.wsClient = wsClient
		self.player = player
	}

	override func _ready() {
		updateRaceTexture()
		updateTerrainTexture()
	}

	private func updateRaceTexture() {
		let resName = "army_logo\(race)"
		imgRace.texture = ResourceLoader.load(path: "res://res/img/\(resName).png") as? Texture2D
	}

	private func updateTerrainTexture() {
		let resName = "terrain_\(terrain)"
		imgTerrain.texture = ResourceLoader.load(path: "res://res/img/\(resName).png") as? Texture2D
	}

	private func saveRaceSelection() {
		player.race = race
		do {
			let msg = NMChangeRace(newRace: UInt8(race))
			let data = try NMEncoder.encode(msg)
			try wsClient.send(data: data)
		} catch {
			//TODO: add error handling
			GD.print("Failed to send message NMChangeRace")
		}
	}

	private func saveTerrainSelection() {
		player.terrain = terrain
		do {
			let msg = NMChangeTerrain(newTerrain: UInt8(terrain))
			let data = try NMEncoder.encode(msg)
			try wsClient.send(data: data)
		} catch {
			//TODO: add error handling
			GD.print("Failed to send message NMChangeTerrain")
		}
	}
}
