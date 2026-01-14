import Foundation
import SwiftGodot
import NetworkModels

@Godot
final class MatchScreen: Node {

	@Export
	var mapContainer: SubViewport!


	private var mapView: MapView!

	//@Export
	//var lineEditUsername: LineEdit!

	//@Callable
	/*func onLoginPressed() {
		GD.print("Login pressed: \(lineEditUsername.text), \(lineEditPassword.text)")
		login()
	}*/

	override func _ready() {
		setupSubViewport()
		createMapView()
	}

	func initialize(settings: NMMatchSettings, players: [NMMatchPlayer]) {
		//TODO: map setup
	}

	private func setupSubViewport() {
		// Enable local input processing for mouse events
		mapContainer.handleInputLocally = true
		
		// Enable physics object picking for Area2D mouse detection
		mapContainer.physicsObjectPicking = true
	}

	private func createMapView() {
		if let mapView = SceneLoader.load(path: "res://Screens/Match/map_view.tscn") as? MapView {
			self.mapView = mapView
			mapContainer.addChild(node: mapView)
		} else {
			//TODO: handle error in more restrictive way, something is very wrong, kick user out?
			GD.print("Failed to load map view")
			ErrorManager.showError(message: "Failed to load map view")
		}
	}
}

