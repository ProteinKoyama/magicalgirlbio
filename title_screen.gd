extends Control

const DialogueScene = preload("res://dialogue.gd")
const TITLE_DIALOG_BGM: AudioStream = preload("res://Assets/MusMus-BGM-174.mp3")

@onready var start_button: BaseButton = %StartButton
@onready var credits_button: BaseButton = $CanvasLayer/CreditsButton
@onready var audio_settings_ui: AudioSettingsUI = $CanvasLayer/AudioSettingsUI
@onready var story_mode_button: Button = %StoryModeButton
@onready var credits_overlay: Control = %CreditsOverlay
@onready var credits_close_button: Button = %CreditsCloseButton
@onready var mit_license_text: Label = $CanvasLayer/CreditsOverlay/Center/Window/Padding/Content/EngineLicensesScroll/EngineLicenses/MitLicenseText
@onready var third_party_licenses: Label = $CanvasLayer/CreditsOverlay/Center/Window/Padding/Content/EngineLicensesScroll/EngineLicenses/ThirdPartyLicenses
@onready var copyright_info: Label = $CanvasLayer/CreditsOverlay/Center/Window/Padding/Content/EngineLicensesScroll/EngineLicenses/CopyrightInfo

var engine_license_content_loaded: bool = false

func _ready() -> void:
	BgmManager.play_bgm(TITLE_DIALOG_BGM)
	start_button.pressed.connect(_start_prologue)
	credits_button.pressed.connect(_open_credits)
	story_mode_button.pressed.connect(_toggle_story_mode)
	credits_close_button.pressed.connect(_close_credits)
	_update_story_mode_button()
	for button: BaseButton in [start_button, credits_button]:
		button.self_modulate = Color.WHITE
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
		button.mouse_exited.connect(_on_button_mouse_exited.bind(button))


func _start_prologue() -> void:
	GameFlow.reset_run()
	if GameFlow.story_enabled:
		DialogueScene.play(get_tree(), "prologue")
	else:
		SceneTransition.change_scene_to_file("res://battle_prep.tscn")


func _toggle_story_mode() -> void:
	GameFlow.story_enabled = not GameFlow.story_enabled
	_update_story_mode_button()


func _update_story_mode_button() -> void:
	story_mode_button.text = "ストーリー：ON" if GameFlow.story_enabled else "ストーリー：OFF"


func _open_credits() -> void:
	if not engine_license_content_loaded:
		_populate_engine_license_content()
	credits_overlay.show()
	for control: Control in [start_button, credits_button, story_mode_button]:
		control.focus_mode = Control.FOCUS_NONE
	audio_settings_ui.set_interaction_enabled(false)
	credits_close_button.grab_focus()


func _populate_engine_license_content() -> void:
	mit_license_text.text = Engine.get_license_text()
	third_party_licenses.text = _format_third_party_licenses(Engine.get_license_info())
	copyright_info.text = _format_copyright_info(Engine.get_copyright_info())
	engine_license_content_loaded = true


func _format_third_party_licenses(licenses: Dictionary) -> String:
	var sections: PackedStringArray = []
	for license_name: Variant in licenses.keys():
		sections.append("%s\n%s" % [str(license_name), str(licenses[license_name])])
	return "\n\n".join(sections)


func _format_copyright_info(components: Array[Dictionary]) -> String:
	var lines: PackedStringArray = []
	for component: Dictionary in components:
		lines.append(str(component.get("name", "")))
		var parts: Array = component.get("parts", [])
		for part_value: Variant in parts:
			if not part_value is Dictionary:
				continue
			var part: Dictionary = part_value as Dictionary
			lines.append("  ライセンス: %s" % str(part.get("license", "")))
			for copyright_owner: Variant in part.get("copyright", []):
				lines.append("  著作権: %s" % str(copyright_owner))
			for file_path: Variant in part.get("files", []):
				lines.append("  対象ファイル: %s" % str(file_path))
		lines.append("")
	return "\n".join(lines)


func _close_credits() -> void:
	credits_overlay.hide()
	for control: Control in [start_button, credits_button, story_mode_button]:
		control.focus_mode = Control.FOCUS_ALL
	audio_settings_ui.set_interaction_enabled(true)
	credits_button.grab_focus()


func _on_button_mouse_entered(button: BaseButton) -> void:
	button.self_modulate = Color(0.52, 0.52, 0.52, 1.0)


func _on_button_mouse_exited(button: BaseButton) -> void:
	button.self_modulate = Color.WHITE
