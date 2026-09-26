extends Control

static var requested_dialogue_path: String = ""

@export var dialogue_path: String = "prologue"

const TITLE_DIALOG_BGM: AudioStream = preload("res://Assets/MusMus-BGM-174.mp3")
const StoryDatabase = preload("res://story_data.gd")
const INACTIVE_PORTRAIT_COLOR := Color(0.42, 0.42, 0.5, 1.0)
const ACTIVE_PORTRAIT_COLOR := Color.WHITE
const CHARACTER_SPEAKER_NAMES := {
	"bio": "ばいお",
	"mascot": "マスコット"
}

var pages: Array[Dictionary] = []
var next_scene: String = ""

var page_index: int = 0
var finished: bool = false

@onready var speaker_label: Label = %Speaker
@onready var dialogue_label: Label = %Dialogue
@onready var skip_button: TextureButton = %SkipButton
@onready var bio_portrait: AnimatedSprite2D = %BioPortrait
@onready var mascot_portrait: Sprite2D = %MascotPortrait
@onready var ending_popup: Control = %EndingPopup
@onready var title_return_button: TextureButton = %TitleReturnButton

var portrait_nodes: Dictionary = {}


## プロローグ・ストーリー・エンディングで共通の入口。
static func play(tree: SceneTree, json_path: String) -> Error:
	requested_dialogue_path = json_path
	var result := tree.change_scene_to_file("res://dialogue.tscn")
	if result != OK:
		requested_dialogue_path = ""
	return result


func _ready() -> void:
	BgmManager.play_bgm(TITLE_DIALOG_BGM)
	portrait_nodes = {
		"bio": bio_portrait,
		"mascot": mascot_portrait
	}
	if not requested_dialogue_path.is_empty():
		dialogue_path = requested_dialogue_path
		requested_dialogue_path = ""
	skip_button.pressed.connect(_finish)
	title_return_button.pressed.connect(_return_to_title)
	if not _load_dialogue():
		speaker_label.text = ""
		dialogue_label.text = "会話データを読み込めませんでした。"
		skip_button.disabled = true
		return
	_show_page()


func _load_dialogue() -> bool:
	var story_id := "prologue" if dialogue_path.ends_with("prologue.json") else dialogue_path
	pages = StoryDatabase.get_pages(story_id, GameFlow.story_index)
	next_scene = StoryDatabase.get_next_scene(story_id)
	if pages.is_empty() or next_scene.is_empty():
		push_error("未登録、または進行範囲外のシナリオです: %s (index %d)" % [story_id, GameFlow.story_index])
		return false
	return true


func _show_page() -> void:
	var page := pages[page_index]
	speaker_label.text = page["speaker"]
	dialogue_label.text = page["text"]
	_update_portraits(page)

func _update_portraits(page: Dictionary) -> void:
	for node_value: Variant in portrait_nodes.values():
		var node := node_value as CanvasItem
		if node == null:
			continue
		node.hide()
	var characters: Array = page.get("characters", [])
	if characters.is_empty():
		characters = _legacy_characters(page)
	var visible_ids: Array[String] = []
	for character_data: Variant in characters:
		if not character_data is Dictionary:
			continue
		var character: Dictionary = character_data as Dictionary
		var character_id := str(character.get("id", ""))
		if not portrait_nodes.has(character_id):
			push_warning("未登録の立ち絵キャラクターです: %s" % character_id)
			continue
		var character_node := portrait_nodes[character_id] as CanvasItem
		if character_node == null:
			continue
		character_node.show()
		visible_ids.append(character_id)
		if character_id == "bio":
			_play_bio_expression(str(character.get("expression", "default")))
	_layout_portraits(visible_ids)
	var speaker_id := str(page.get("speaker_id", _speaker_id_from_name(str(page.get("speaker", "")))))
	for character_id: String in visible_ids:
		var character_node := portrait_nodes[character_id] as CanvasItem
		if character_node == null:
			continue
		var is_active := speaker_id.is_empty() or character_id == speaker_id
		character_node.modulate = ACTIVE_PORTRAIT_COLOR if is_active else INACTIVE_PORTRAIT_COLOR

func _play_bio_expression(expression: String) -> void:
	var animation_name := StringName(expression)
	if not bio_portrait.sprite_frames.has_animation(animation_name):
		push_warning("未登録のばいお立ち絵アニメーションです: %s" % expression)
		animation_name = &"default"
	bio_portrait.play(animation_name)

func _layout_portraits(character_ids: Array[String]) -> void:
	if character_ids.is_empty():
		return
	var viewport_width: float = get_viewport_rect().size.x
	for index in character_ids.size():
		var character_id: String = character_ids[index]
		var center_x: float = viewport_width * float(index + 1) / float(character_ids.size() + 1)
		var node := portrait_nodes[character_id] as Node2D
		if node == null:
			continue
		var texture_size: Vector2 = _portrait_texture_size(character_id)
		node.position.x = center_x - texture_size.x * node.scale.x * 0.5

func _portrait_texture_size(character_id: String) -> Vector2:
	if character_id == "bio":
		var texture: Texture2D = bio_portrait.sprite_frames.get_frame_texture(
			bio_portrait.animation,
			bio_portrait.frame
		)
		return texture.get_size() if texture != null else Vector2.ZERO
	if character_id == "mascot" and mascot_portrait.texture != null:
		return mascot_portrait.texture.get_size()
	return Vector2.ZERO

func _legacy_characters(page: Dictionary) -> Array:
	var portrait_name := str(page.get("portrait", "default"))
	if portrait_name == "hide":
		return []
	var speaker_id := _speaker_id_from_name(str(page.get("speaker", "")))
	if speaker_id == "mascot":
		return [{"id": "mascot", "expression": "default"}]
	return [{"id": "bio", "expression": portrait_name}]

func _speaker_id_from_name(speaker_name: String) -> String:
	for character_id: String in CHARACTER_SPEAKER_NAMES:
		if CHARACTER_SPEAKER_NAMES[character_id] == speaker_name:
			return character_id
	return ""


func _advance() -> void:
	if finished or pages.is_empty():
		return
	if page_index + 1 >= pages.size():
		_finish()
	else:
		page_index += 1
		_show_page()


func _finish() -> void:
	if finished or next_scene.is_empty():
		return
	if dialogue_path == "ending":
		finished = true
		skip_button.hide()
		ending_popup.show()
		title_return_button.grab_focus()
		return
	finished = true
	var result := get_tree().change_scene_to_file(next_scene)
	if result != OK:
		finished = false
		push_error("会話の終了後に遷移できません: %s (error %d)" % [next_scene, result])


func _return_to_title() -> void:
	var result := get_tree().change_scene_to_file(next_scene)
	if result != OK:
		push_error("タイトル画面へ遷移できません: %s (error %d)" % [next_scene, result])


func _input(event: InputEvent) -> void:
	if ending_popup.visible:
		return
	if not event is InputEventMouseButton:
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	var skip_local_position: Vector2 = skip_button.get_global_transform_with_canvas().affine_inverse() * mouse_event.position
	if Rect2(Vector2.ZERO, skip_button.size).has_point(skip_local_position):
		return
	get_viewport().set_input_as_handled()
	_advance()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_advance()
