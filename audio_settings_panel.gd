class_name AudioSettingsPanel
extends NinePatchRect

@onready var bgm_slider: HSlider = $Margin/Rows/BgmRow/BgmSlider
@onready var se_slider: HSlider = $Margin/Rows/SeRow/SeSlider
@onready var bgm_value: Label = $Margin/Rows/BgmRow/BgmValue
@onready var se_value: Label = $Margin/Rows/SeRow/SeValue


func _ready() -> void:
	bgm_slider.set_value_no_signal(BgmManager.get_bus_volume_percent(&"BGM"))
	se_slider.set_value_no_signal(BgmManager.get_bus_volume_percent(&"SE"))
	bgm_slider.value_changed.connect(_on_bgm_changed)
	se_slider.value_changed.connect(_on_se_changed)
	_update_bgm_value(bgm_slider.value)
	_update_se_value(se_slider.value)


func set_interaction_enabled(enabled: bool) -> void:
	for slider: HSlider in [bgm_slider, se_slider]:
		slider.editable = enabled
		slider.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE


func _on_bgm_changed(value: float) -> void:
	_update_bgm_value(value)
	BgmManager.set_bus_volume_percent(&"BGM", value)


func _on_se_changed(value: float) -> void:
	_update_se_value(value)
	BgmManager.set_bus_volume_percent(&"SE", value)


func _update_bgm_value(value: float) -> void:
	bgm_value.text = "%d%%" % roundi(value)


func _update_se_value(value: float) -> void:
	se_value.text = "%d%%" % roundi(value)
