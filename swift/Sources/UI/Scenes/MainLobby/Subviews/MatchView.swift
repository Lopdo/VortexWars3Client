import Foundation
import NetworkModels
import SwiftGodot

extension CustomMatchView: SceneLoadable {
	static var pathToScene: String {
		"res://Screens/MainLobby/custom_match_view.tscn"
	}
}

@Godot
class CustomMatchView: Button {
	@Export
	var lblName: Label!

	@Export
	var lblPlayerCount: Label!

	@Export
	var lblCombatRule: Label!

	@Export
	var lblStartType: Label!

	@Export
	var lblReinforcementRule: Label!

	@Export
	var lblBoostsEnabled: Label!

	@Export
	var lblMapSize: Label!

	var matchId: String = ""

	func setup(with match: MatchDTO) {
		matchId = match.id
		lblName.text = match.settings.matchName
		lblPlayerCount.text = "\(match.playerCount)/\(match.settings.maxPlayers)"

		lblStartType.text = match.settings.startCondition == .empty ? "Conquest" : "Full"
		lblCombatRule.text =
			switch match.settings.combatRule {
				case .attrition: "Attrition"
				case .hardcore: "Hardcore"
				case .oneOnOne: "1on1"
			}
		lblReinforcementRule.text =
			switch match.settings.reinforcementsRule {
				case .borders: "Borders"
				case .random: "Random"
				case .manual: "Manual"
			}
		lblBoostsEnabled.text = match.settings.boosterEnabled ? "Boosts Enabled" : "Boosts Disabled"

		setMapIcon(mapType: match.settings.mapType)
	}

	private func setMapIcon(mapType: NMMatchSettings.MapType) {
		switch mapType {
			case .random(let size):
				switch size {
					case .small: lblMapSize.text = "S"
					case .medium: lblMapSize.text = "M"
					case .large: lblMapSize.text = "L"
					case .huge: lblMapSize.text = "XL"
					case .gigantic: lblMapSize.text = "XXL"
				}
			case .premade(_):
				lblMapSize.text = "?"
		}
	}
}
