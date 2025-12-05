// SPDX-License-Identifier: Unlicense or CC0
// source:
// https://gist.github.com/thygrrr/8288cabeb5cd25031ce6132c4a886311#file-camerazoomandpan-gd
//extends Node2D

// Smooth panning and precise zooming for Camera2D
// Usage: This script may be placed on a child node
// of a Camera2D or on a Camera2D itself.
// Suggestion: Change and/or set up the three Input Actions,
// otherwise the mouse will fall back to hard-wired mouse
// buttons and you will miss out on alternative bindings,
// deadzones, and other nice things from the project InputMap.

import Foundation
import SwiftGodot

@Godot
class CameraZoomAndPan: Camera2D {
	
	@Export
	var mapSize: Vector2 = Vector2(x: 1000, y: 1000)
	
	@Export
	var zoomStepRatio: Double = 0.1
	
	@Export
	var panAction: StringName = "camera>pan"
	
	@Export
	var zoomInAction: StringName = "camera>zoom+"
	
	@Export
	var zoomOutAction: StringName = "camera>zoom-"
	
	@Export
	var zoomToCursor: Bool = true
	
	@Export
	var useFallbackButtons: String = "Auto" // "Auto", "Always", "Never"
	
	@Export
	var panButton: MouseButton = .middle
	
	@Export
	var zoomInButton: MouseButton = .wheelUp
	
	@Export
	var zoomOutButton: MouseButton = .wheelDown
	
	@Export
	var panSmoothing: Double = 0.5
	@Export
	var zoomSmoothing: Double = 0.5	

	let sliderExponent: Double = 0.25
	let referenceFPS: Double = 120.0
	
	var zoomGoal: Vector2 = .zero
	var positionGoal: Vector2 = .zero
	
	var fallbackMousePan: Bool = false
	var fallbackMouseZoomIn: Bool = false
	var fallbackMouseZoomOut: Bool = false
	var lastMouse: Vector2 = Vector2()
	var zoomMouse: Vector2 = Vector2()
	var minZoom: Double = 0.25
	let maxZoom: Double = 8.0
	var mapViewSize: Vector2 = Vector2()
	
	override func _ready() {
		panSmoothing = pow(panSmoothing, sliderExponent)
		zoomSmoothing = pow(zoomSmoothing, sliderExponent)

		zoomGoal = zoom
		positionGoal = position
		
		let actions = InputMap.getActions()
		let always = useFallbackButtons == "Always"
		let never = useFallbackButtons == "Never"
		fallbackMousePan = !never && (always || !actions.contains(panAction))
		fallbackMouseZoomIn = !never && (always || !actions.contains(zoomInAction))
		fallbackMouseZoomOut = !never && (always || !actions.contains(zoomOutAction))
		if !always && (fallbackMousePan || fallbackMouseZoomIn || fallbackMouseZoomOut) {
			print("CameraZoomAndPan: Mouse Fallbacks for Actions in effect! " +
				"\(panAction)=\(fallbackMousePan) " +
				"\(zoomInAction)=\(fallbackMouseZoomIn) " +
				"\(zoomOutAction)=\(fallbackMouseZoomOut)")
			print("CameraZoomAndPan: TIP - set up all three of the following InputActions: \(panAction), \(zoomInAction), \(zoomOutAction)")
		}
	}

	override func _process(delta: Double) {
		let kPan = pow(panSmoothing, referenceFPS * delta)
		let kZoom = pow(zoomSmoothing, referenceFPS * delta)
		
		let mousePreZoom = toLocal(globalPoint: getCanvasTransform().affineInverse().basisXform(v: zoomMouse))
		zoom = zoom * kZoom + zoomGoal * (1.0 - kZoom)
		let mousePostZoom = toLocal(globalPoint: getCanvasTransform().affineInverse().basisXform(v: zoomMouse))
		
		let zoomPositionOffset = zoomToCursor ? (mousePreZoom - mousePostZoom) : Vector2.zero
		
		positionGoal += zoomPositionOffset
		position = position * kPan + positionGoal * (1.0 - kPan) + zoomPositionOffset
	}

	override func _unhandledInput(event: InputEvent?) {
		guard let event,
		      let viewport = getViewport() else 
		{
			return
		}

		if !(event is InputEventMouse) && !(event is InputEventAction) {
			return
		}
		
		let currentMouse = getLocalMousePosition()
		if Input.isActionPressed(action: panAction) || (fallbackMousePan && Input.isMouseButtonPressed(button: panButton)) {
			positionGoal += (lastMouse - currentMouse)
		}
		
		if Input.isActionJustPressed(action: zoomInAction) || (fallbackMouseZoomIn && Input.isMouseButtonPressed(button: zoomInButton)) {
			zoomGoal *= 1.0 / (1.0 - zoomStepRatio)
			zoomMouse = viewport.getMousePosition()
			zoomMouse -= getViewportRect().size * 0.5
		}
		
		if Input.isActionJustPressed(action: zoomOutAction) || (fallbackMouseZoomOut && Input.isMouseButtonPressed(button: zoomOutButton)) {
			zoomGoal *= (1.0 - zoomStepRatio)
			zoomMouse = viewport.getMousePosition()
			zoomMouse -= getViewportRect().size * 0.5
		}
		
		clampGoals()

		lastMouse = currentMouse
	}

	private func clampGoals() {
		zoomGoal = zoomGoal.clamp(min: Vector2.one * minZoom, max: Vector2.one * maxZoom)
		
		if mapSize.x <= (mapViewSize.x / 0.8) / zoomGoal.x {
			positionGoal.x = mapSize.x / 2
		} else {
			positionGoal.x = max(mapViewSize.x / 4 / zoomGoal.x, positionGoal.x)
			positionGoal.x = min(mapSize.x - mapViewSize.x / 4 / zoomGoal.x, positionGoal.x)
		}
		if mapSize.y <= (mapViewSize.y / 0.8) / zoomGoal.y {
			positionGoal.y = mapSize.y / 2
		} else {
			positionGoal.y = max(mapViewSize.y / 4 / zoomGoal.y, positionGoal.y)
			positionGoal.y = min(mapSize.y - mapViewSize.y / 4 / zoomGoal.y, positionGoal.y)
		}
	}

	func setMapView(size: Vector2) {
		mapViewSize = size
		minZoom = min(Double(min(mapViewSize.x / mapSize.x, mapViewSize.y / mapSize.y)) * 0.8, 1.0)

		clampGoals()
		
		zoom = zoomGoal
		position = positionGoal
	}
}
