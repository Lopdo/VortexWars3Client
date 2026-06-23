import Foundation
import NetworkModels
import SwiftGodot

@Godot
final class MatchLobbyPlayerInfoView: Control {

	private var factionIndex: Int = 1
	private var terrainIndex: Int = 1

	private var wsClient: WebSocketClient!
	private var player: Player!

	@Export
	var imgFaction: TextureRect!

	@Export
	var imgTerrain: TextureRect!

	@Callable
	func onNextFaction() {
		factionIndex = (factionIndex + 1) % player.unlockedFactions.count
		updateFactionTexture()
		saveFactionSelection()
	}

	@Callable
	func onPrevFaction() {
		factionIndex -= 1
		if factionIndex < 0 {
			factionIndex = player.unlockedFactions.count - 1
		}
		updateFactionTexture()
		saveFactionSelection()
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
		factionIndex = player.faction
		self.wsClient = wsClient
		self.player = player
	}

	override func _ready() {
		updateFactionTexture()
		updateTerrainTexture()
	}

	private func updateFactionTexture() {
		let resName = "army_logo\(player.unlockedFactions[factionIndex])"
		imgFaction.texture = ResourceLoader.load(path: "res://res/img/\(resName).png") as? Texture2D
	}

	private func updateTerrainTexture() {
		let resName = "terrain_\(player.unlockedTerrains[terrainIndex])"
		imgTerrain.texture = ResourceLoader.load(path: "res://res/img/\(resName).png") as? Texture2D
	}

	private func saveFactionSelection() {
		player.faction = player.unlockedFactions[factionIndex]
		do {
			let msg = NMChangeFaction(newFaction: UInt8(player.faction))
			let data = try NMEncoder.encode(msg)
			try wsClient.send(data: data)
		} catch {
			//TODO: add error handling
			GD.print("Failed to send message NMChangeFaction")
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
