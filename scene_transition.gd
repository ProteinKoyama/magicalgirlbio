extends CanvasLayer

const WIPE_DURATION := 0.5
const REVEAL_DURATION := 0.5
const BATTLE_FADE_OUT_DURATION := 0.5
const BATTLE_FADE_IN_DURATION := 0.5

@onready var wipe: ColorRect = $Wipe
@onready var input_blocker: ColorRect = $InputBlocker

var transitioning := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	wipe.hide()
	input_blocker.hide()


func change_scene_to_file(scene_path: String) -> Error:
	if transitioning:
		return ERR_BUSY
	if not ResourceLoader.exists(scene_path):
		return ERR_FILE_NOT_FOUND
	transitioning = true
	input_blocker.show()
	_run_transition(scene_path)
	return OK


func _run_transition(scene_path: String) -> void:
	var current_scene: Node = get_tree().current_scene
	var fade_to_battle: bool = (
		current_scene != null
		and current_scene.scene_file_path == "res://battle_prep.tscn"
		and scene_path == "res://battle.tscn"
	)
	var reveal_to_left: bool = not fade_to_battle
	if fade_to_battle:
		await _run_battle_fade(scene_path)
		return

	wipe.color = Color.BLACK
	wipe.show()
	wipe.position = Vector2(get_viewport().get_visible_rect().size.x, 0.0)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(wipe, "position:x", 0.0, WIPE_DURATION)
	await tween.finished

	var result: Error = get_tree().change_scene_to_file(scene_path)
	if result != OK:
		push_error("シーンを切り替えられません: %s (error %d)" % [scene_path, result])
		wipe.hide()
		input_blocker.hide()
		transitioning = false
		return

	await get_tree().process_frame
	if not reveal_to_left:
		wipe.hide()
		wipe.position = Vector2.ZERO
		input_blocker.hide()
		transitioning = false
		return

	var reveal_tween: Tween = create_tween()
	reveal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	reveal_tween.set_trans(Tween.TRANS_QUAD)
	reveal_tween.set_ease(Tween.EASE_IN_OUT)
	reveal_tween.tween_property(
		wipe,
		"position:x",
		-get_viewport().get_visible_rect().size.x,
		REVEAL_DURATION
	)
	await reveal_tween.finished
	wipe.hide()
	wipe.position = Vector2.ZERO
	input_blocker.hide()
	transitioning = false


func _run_battle_fade(scene_path: String) -> void:
	wipe.position = Vector2.ZERO
	wipe.color = Color(0, 0, 0, 0)
	wipe.show()
	var fade_out_tween: Tween = create_tween()
	fade_out_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_out_tween.set_trans(Tween.TRANS_LINEAR)
	fade_out_tween.tween_property(wipe, "color:a", 1.0, BATTLE_FADE_OUT_DURATION)
	await fade_out_tween.finished

	var result: Error = get_tree().change_scene_to_file(scene_path)
	if result != OK:
		push_error("戦闘画面へ切り替えられません: %s (error %d)" % [scene_path, result])
		wipe.hide()
		wipe.color = Color.BLACK
		input_blocker.hide()
		transitioning = false
		return

	await get_tree().process_frame
	var fade_in_tween: Tween = create_tween()
	fade_in_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_in_tween.set_trans(Tween.TRANS_LINEAR)
	fade_in_tween.tween_property(wipe, "color:a", 0.0, BATTLE_FADE_IN_DURATION)
	await fade_in_tween.finished
	wipe.hide()
	wipe.color = Color.BLACK
	input_blocker.hide()
	transitioning = false
