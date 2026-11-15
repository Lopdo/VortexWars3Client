import Foundation
import NetworkModels
import SwiftGodot

@Godot
final class CustomMatchLobbyMatchInfoView: Control {

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

	func initialize(with settings: NMMatchSettings) {
		lblName.text = settings.matchName
		lblPlayerCount.text = "\(settings.maxPlayers)"

		lblStartType.text = settings.startCondition == .empty ? "Conquest" : "Full"
		lblCombatRule.text =
			switch settings.combatRule {
				case .attrition: "Attrition"
				case .hardcore: "Hardcore"
				case .oneOnOne: "1on1"
			}
		lblReinforcementRule.text =
			switch settings.reinforcementsRule {
				case .borders: "Borders"
				case .random: "Random"
				case .manual: "Manual"
			}
		lblBoostsEnabled.text = settings.boosterEnabled ? "Boosts Enabled" : "Boosts Disabled"

		setMapIcon(mapType: settings.mapType)
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
