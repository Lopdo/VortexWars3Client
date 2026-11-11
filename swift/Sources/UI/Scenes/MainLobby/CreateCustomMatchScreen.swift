import Foundation
import NetworkModels
import SwiftGodot

extension CreateCustomMatchScreen: SceneLoadable {
	static var pathToScene: String {
		"res://Screens/MainLobby/create_custom_game_screen.tscn"
	}
}

@Godot
final class CreateCustomMatchScreen: Control {

	@Export
	private var lineEditMapName: LineEdit!

	@Export(.nodeType)
	private var viewMaxPlayers: SelectableOptionRow!

	@Export(.nodeType)
	private var viewCombatRule: SelectableOptionRow!

	@Export(.nodeType)
	private var viewReinforcements: SelectableOptionRow!

	@Export(.nodeType)
	private var viewStartCondition: SelectableOptionRow!

	@Export(.nodeType)
	private var viewBoostsEnabled: SelectableOptionRow!

	@Export(.nodeType)
	private var viewMapType: SelectableOptionRow!

	@Export(.nodeType)
	private var viewRandomMapSize: SelectableOptionRow!

	private var user: User!

	override func _ready() {
		viewMaxPlayers.options = (2...8).map { SelectableOption(title: "\($0)", id: $0) }
		viewMaxPlayers.currentOption = SelectableOption(title: "4", id: 4)

		viewCombatRule.options = [
			NMMatchSettings.CombatRule.hardcore,
			NMMatchSettings.CombatRule.attrition,
			NMMatchSettings.CombatRule.oneOnOne,
		]
		.map { SelectableOption(title: $0.title, id: $0.id) }

		viewReinforcements.options = [
			NMMatchSettings.ReinforcementsRule.borders,
			NMMatchSettings.ReinforcementsRule.random,
			NMMatchSettings.ReinforcementsRule.manual,
		]
		.map { SelectableOption(title: $0.title, id: $0.id) }

		viewStartCondition.options = [
			NMMatchSettings.StartCondition.empty,
			NMMatchSettings.StartCondition.full,
		]
		.map { SelectableOption(title: $0.title, id: $0.id) }

		viewBoostsEnabled.options = [
			SelectableOption(title: "Enabled", id: 1),
			SelectableOption(title: "Disabled", id: 0),
		]

		viewMapType.options = [
			SelectableOption(title: "Random", id: 0)
		]

		viewRandomMapSize.options = [
			NMMatchSettings.MapSize.small,
			NMMatchSettings.MapSize.medium,
			NMMatchSettings.MapSize.large,
			NMMatchSettings.MapSize.huge,
			NMMatchSettings.MapSize.gigantic,
		]
		.map { SelectableOption(title: $0.title, id: $0.id) }
	}

	func initialize(user: User) {
		self.user = user
	}

	@Callable
	private func startGame() {
		let client = WebSocketClient()
		addChild(node: client)

		do {
			let settings = try validateMatchSettings()

			GD.print(settings)

			MatchService.createMatch(
				on: self,
				settings: settings,
				user: user,
				webSocketClient: client,
				onError: { error in
					GD.print("Failed to create match: \(error)")
					ErrorManager.showError(message: "Failed to create match: \(error)")
					self.removeChild(node: client)
				}
			)
		} catch {
			GD.print("Failed to validate match settings: \(error)")
			ErrorManager.showError(message: error.errorMessage)
			self.removeChild(node: client)
		}
	}

	private func validateMatchSettings() throws(MatchSettingsValidationError) -> NMMatchSettings {
		guard lineEditMapName.text.count > 2 else {
			throw .nameTooShort
		}

		guard let startCondition = NMMatchSettings.StartCondition.create(from: viewStartCondition.currentOption.id),
			let combatRule = NMMatchSettings.CombatRule.create(from: viewCombatRule.currentOption.id),
			let reinforcementRule = NMMatchSettings.ReinforcementsRule.create(from: viewReinforcements.currentOption.id)
		else {
			throw .settingsCorrupted
		}

		let map: NMMatchSettings.MapType
		if viewMapType.currentOption.id == 0 {
			if let mapSize = NMMatchSettings.MapSize.create(from: viewRandomMapSize.currentOption.id) {
				map = .random(mapSize)
			} else {
				throw .settingsCorrupted
			}
		} else {
			throw .settingsCorrupted
		}

		return NMMatchSettings(
			mapType: map,
			gameName: lineEditMapName.text,
			maxPlayers: viewMaxPlayers.currentOption.id,
			startCondition: startCondition,
			combatRule: combatRule,
			reinforcementsRule: reinforcementRule,
			boosterEnabled: viewBoostsEnabled.currentOption.id == 1
		)
	}

}

private enum MatchSettingsValidationError: Error {
	case nameTooShort
	case settingsCorrupted

	var errorMessage: String {
		switch self {
			case .nameTooShort: "Name of the match is too short, it needs to be at least 3 characters"
			case .settingsCorrupted: "Unexpected error occured, exit to main menu and try again please"
		}
	}
}

extension NMMatchSettings.MapSize {
	var title: String {
		switch self {
			case .small: "Small"
			case .medium: "Medium"
			case .large: "Large"
			case .huge: "Huge"
			case .gigantic: "Gigantic"
		}
	}

	var id: Int {
		switch self {
			case .small: 1
			case .medium: 2
			case .large: 3
			case .huge: 4
			case .gigantic: 5
		}
	}

	static func create(from id: Int) -> Self? {
		switch id {
			case 1: .small
			case 2: .medium
			case 3: .large
			case 4: .huge
			case 5: .gigantic
			default: nil
		}
	}
}

extension NMMatchSettings.MapType {
	var title: String {
		switch self {
			case .premade(_): "Premade"
			case .random(_): "Random"
		}
	}
}

extension NMMatchSettings.StartCondition {
	var title: String {
		switch self {
			case .empty: "Conquest"
			case .full: "Full"
		}
	}

	var id: Int {
		switch self {
			case .empty: 1
			case .full: 2
		}
	}

	static func create(from id: Int) -> Self? {
		switch id {
			case 1: .empty
			case 2: .full
			default: nil
		}
	}
}

extension NMMatchSettings.CombatRule {
	var title: String {
		switch self {
			case .hardcore: "Hardcore"
			case .attrition: "Attrition"
			case .oneOnOne: "1 on 1"
		}
	}

	var id: Int {
		switch self {
			case .hardcore: 1
			case .attrition: 2
			case .oneOnOne: 3
		}
	}

	static func create(from id: Int) -> Self? {
		switch id {
			case 1: .hardcore
			case 2: .attrition
			case 3: .oneOnOne
			default: nil
		}
	}
}

extension NMMatchSettings.ReinforcementsRule {
	var title: String {
		switch self {
			case .manual: "Manual"
			case .random: "Random"
			case .borders: "Borders"
		}
	}

	var id: Int {
		switch self {
			case .manual: 1
			case .random: 2
			case .borders: 3
		}
	}

	static func create(from id: Int) -> Self? {
		switch id {
			case 1: .manual
			case 2: .random
			case 3: .borders
			default: nil
		}
	}
}
