class_name AudioSettingsUI
extends Control

@onready var panel: AudioSettingsPanel = $AudioSettingsPanel
@onready var toggle_button: Button = $AudioToggleButton
@onready var close_button: Button = $AudioCloseButton


func _ready() -> void:
	toggle_button.pressed.connect(_open_panel)
	close_button.pressed.connect(_close_panel)
	get_viewport().size_changed.connect(_position_panel)
	_position_panel()


func set_interaction_enabled(enabled: bool) -> void:
	toggle_button.disabled = not enabled
	close_button.disabled = not enabled
	panel.set_interaction_enabled(enabled)


func is_pointer_over_controls(viewport_position: Vector2) -> bool:
	if toggle_button.visible and _control_contains_viewport_position(toggle_button, viewport_position):
		return true
	if close_button.visible and _control_contains_viewport_position(close_button, viewport_position):
		return true
	return panel.visible and _control_contains_viewport_position(panel, viewport_position)


func _control_contains_viewport_position(control: Control, viewport_position: Vector2) -> bool:
	var local_position: Vector2 = control.get_global_transform_with_canvas().affine_inverse() * viewport_position
	return Rect2(Vector2.ZERO, control.size).has_point(local_position)


func _open_panel() -> void:
	panel.show()
	toggle_button.hide()
	close_button.show()
	panel.set_interaction_enabled(true)
	close_button.grab_focus()


func _close_panel() -> void:
	panel.hide()
	close_button.hide()
	toggle_button.show()
	toggle_button.grab_focus()


func _position_panel() -> void:
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(
		toggle_button.position.x - panel.size.x * panel.scale.x - 12.0,
		toggle_button.position.y
	)
