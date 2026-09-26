extends Control

const DialogueScene = preload("res://dialogue.gd")
const TITLE_DIALOG_BGM: AudioStream = preload("res://Assets/MusMus-BGM-174.mp3")

@onready var start_button: BaseButton = %StartButton
@onready var credits_button: BaseButton = $CanvasLayer/CreditsButton
@onready var bgm_slider: HSlider = %BgmSlider
@onready var se_slider: HSlider = %SeSlider
@onready var bgm_value: Label = %BgmValue
@onready var se_value: Label = %SeValue
@onready var credits_overlay: Control = %CreditsOverlay
@onready var credits_close_button: Button = %CreditsCloseButton


func _ready() -> void:
	BgmManager.play_bgm(TITLE_DIALOG_BGM)
	bgm_slider.set_value_no_signal(BgmManager.get_bus_volume_percent(&"BGM"))
	se_slider.set_value_no_signal(BgmManager.get_bus_volume_percent(&"SE"))
	start_button.pressed.connect(_start_prologue)
	credits_button.pressed.connect(_open_credits)
	credits_close_button.pressed.connect(_close_credits)
	credits_overlay.gui_input.connect(_on_credits_overlay_gui_input)
	for button: BaseButton in [start_button, credits_button]:
		button.self_modulate = Color.WHITE
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
		button.mouse_exited.connect(_on_button_mouse_exited.bind(button))
	bgm_slider.value_changed.connect(_on_bgm_changed)
	se_slider.value_changed.connect(_on_se_changed)
	_on_bgm_changed(bgm_slider.value)
	_on_se_changed(se_slider.value)


func _start_prologue() -> void:
	GameFlow.reset_run()
	DialogueScene.play(get_tree(), "prologue")


func _open_credits() -> void:
	credits_overlay.show()
	for control: Control in [start_button, credits_button, bgm_slider, se_slider]:
		control.focus_mode = Control.FOCUS_NONE
	credits_close_button.grab_focus()


func _close_credits() -> void:
	credits_overlay.hide()
	for control: Control in [start_button, credits_button, bgm_slider, se_slider]:
		control.focus_mode = Control.FOCUS_ALL
	credits_button.grab_focus()


func _on_credits_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		credits_overlay.accept_event()
		_close_credits()


func _unhandled_key_input(event: InputEvent) -> void:
	if credits_overlay.visible and event.is_action_pressed("ui_cancel"):
		_close_credits()
		get_viewport().set_input_as_handled()


func _on_button_mouse_entered(button: BaseButton) -> void:
	button.self_modulate = Color(0.52, 0.52, 0.52, 1.0)


func _on_button_mouse_exited(button: BaseButton) -> void:
	button.self_modulate = Color.WHITE


func _on_bgm_changed(value: float) -> void:
	bgm_value.text = "%d%%" % roundi(value)
	_set_bus_volume("BGM", value)


func _on_se_changed(value: float) -> void:
	se_value.text = "%d%%" % roundi(value)
	_set_bus_volume("SE", value)


func _set_bus_volume(bus_name: StringName, value: float) -> void:
	BgmManager.set_bus_volume_percent(bus_name, value)
