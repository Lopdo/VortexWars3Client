import Foundation
import SwiftGodot

@Godot
final class ProfilePlayerInfoView: PanelContainer {

	@Export
	private var lblName: Label!

	@Export
	private var lblLevel: Label!

	@Export
	private var lblRank: Label!

	@Export
	private var lblCurrency: Label!

	private var player: Player!

	func initialize(player: Player) {
		self.player = player
	}

	override func _ready() {
		lblName.text = player.name
		lblLevel.text = String(player.level)
	}

}
