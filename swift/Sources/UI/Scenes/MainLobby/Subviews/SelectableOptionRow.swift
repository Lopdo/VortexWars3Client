import Foundation
import SwiftGodot

@Godot
final class SelectableOptionRow: PanelContainer {

	@Export
	private var buttonLeft: Button!

	@Export
	private var buttonRight: Button!

	@Export
	private var labelCurrent: Label!

	@Export
	private var cyclical: Bool = false

	var options: [SelectableOption] = [] {
		didSet {
			updateButtonStates()
			labelCurrent.text = currentOption.title
		}
	}

	private var currentIndex: Int = 0
	var currentOption: SelectableOption {
		get {
			options[currentIndex]
		}
		set {
			currentIndex = options.firstIndex(of: newValue) ?? 0
			updateButtonStates()
			labelCurrent.text = options[currentIndex].title
		}
	}

	override func _ready() {
		updateButtonStates()
	}

	@Callable
	private func onLeftButtonPressed() {
		if cyclical && currentIndex == 0 {
			currentIndex = options.count - 1
		} else {
			currentIndex -= 1
		}

		updateButtonStates()
		labelCurrent.text = currentOption.title
	}

	@Callable func onRightButtonPressed() {
		if cyclical && currentIndex == options.count - 1 {
			currentIndex = 0
		} else {
			currentIndex += 1
		}

		updateButtonStates()
		labelCurrent.text = currentOption.title
	}

	private func updateButtonStates() {
		//We populate the view with data in parent's _ready, but this _ready is called before parent
		//so we don't have any data yet
		guard !options.isEmpty else { return }

		if !cyclical {
			buttonLeft.disabled = currentOption == options.first
			buttonRight.disabled = currentOption == options.last
		}
	}
}

struct SelectableOption: Equatable {
	let title: String
	let id: Int
}
