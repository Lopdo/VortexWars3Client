import Foundation
import SwiftGodot

@Godot
final class MatchScene: Node {

	@Export
	var mapView: MapView!

	//@Export
	//var lineEditUsername: LineEdit!

	//@Callable
	/*func onLoginPressed() {
		GD.print("Login pressed: \(lineEditUsername.text), \(lineEditPassword.text)")
		login()
	}*/
}

