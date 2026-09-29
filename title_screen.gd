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
@onready var mit_license_text: Label = $CanvasLayer/CreditsOverlay/Center/Window/Padding/Content/EngineLicensesScroll/EngineLicenses/MitLicenseText
@onready var third_party_licenses: Label = $CanvasLayer/CreditsOverlay/Center/Window/Padding/Content/EngineLicensesScroll/EngineLicenses/ThirdPartyLicenses
@onready var copyright_info: Label = $CanvasLayer/CreditsOverlay/Center/Window/Padding/Content/EngineLicensesScroll/EngineLicenses/CopyrightInfo

var engine_license_content_loaded: bool = false

func _ready() -> void:
	BgmManager.play_bgm(TITLE_DIALOG_BGM)
	bgm_slider.set_value_no_signal(BgmManager.get_bus_volume_percent(&"BGM"))
	se_slider.set_value_no_signal(BgmManager.get_bus_volume_percent(&"SE"))
	start_button.pressed.connect(_start_prologue)
	credits_button.pressed.connect(_open_credits)
	credits_close_button.pressed.connect(_close_credits)
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
	if not engine_license_content_loaded:
		_populate_engine_license_content()
	credits_overlay.show()
	for control: Control in [start_button, credits_button, bgm_slider, se_slider]:
		control.focus_mode = Control.FOCUS_NONE
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
	for control: Control in [start_button, credits_button, bgm_slider, se_slider]:
		control.focus_mode = Control.FOCUS_ALL
	credits_button.grab_focus()


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
