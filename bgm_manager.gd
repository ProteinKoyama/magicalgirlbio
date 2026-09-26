extends Node

const SILENT_VOLUME_DB := -80.0
const DEFAULT_BGM_VOLUME_PERCENT := 20.0
const DEFAULT_SE_VOLUME_PERCENT := 50.0

var players: Array[AudioStreamPlayer] = []
var active_player_index := 0
var current_stream: AudioStream
var fade_tween: Tween
var transition_version := 0
var bgm_volume_percent := DEFAULT_BGM_VOLUME_PERCENT
var se_volume_percent := DEFAULT_SE_VOLUME_PERCENT


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_bus_volume(&"BGM", bgm_volume_percent)
	_apply_bus_volume(&"SE", se_volume_percent)
	for index in 2:
		var player := AudioStreamPlayer.new()
		player.name = "BGMPlayer%d" % (index + 1)
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.bus = &"BGM"
		player.volume_db = SILENT_VOLUME_DB
		add_child(player)
		players.append(player)


func set_bus_volume_percent(bus_name: StringName, value: float) -> void:
	var clamped_value := clampf(value, 0.0, 100.0)
	match bus_name:
		&"BGM":
			bgm_volume_percent = clamped_value
		&"SE":
			se_volume_percent = clamped_value
	_apply_bus_volume(bus_name, clamped_value)


func get_bus_volume_percent(bus_name: StringName) -> float:
	if bus_name == &"BGM":
		return bgm_volume_percent
	if bus_name == &"SE":
		return se_volume_percent
	return 100.0


func _apply_bus_volume(bus_name: StringName, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value / 100.0))
	AudioServer.set_bus_mute(bus_index, is_zero_approx(value))


func play_bgm(stream: AudioStream, fade_duration := 0.5) -> void:
	if stream == null:
		stop_bgm(fade_duration)
		return
	var active_player := players[active_player_index]
	if current_stream == stream and active_player.playing:
		return
	transition_version += 1
	var version := transition_version
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()

	_set_stream_loop(stream)
	if not active_player.playing:
		active_player.stream = stream
		active_player.volume_db = 0.0
		active_player.play()
		current_stream = stream
		return

	var previous_player := active_player
	active_player_index = 1 - active_player_index
	var next_player := players[active_player_index]
	next_player.stop()
	next_player.stream = stream
	next_player.volume_db = SILENT_VOLUME_DB
	next_player.play()
	current_stream = stream

	fade_tween = create_tween().set_parallel(true)
	fade_tween.tween_property(previous_player, "volume_db", SILENT_VOLUME_DB, fade_duration)
	fade_tween.tween_property(next_player, "volume_db", 0.0, fade_duration)
	fade_tween.finished.connect(_finish_crossfade.bind(previous_player, version), CONNECT_ONE_SHOT)


func stop_bgm(fade_duration := 0.5) -> void:
	transition_version += 1
	var version := transition_version
	current_stream = null
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	var active_player := players[active_player_index]
	if not active_player.playing:
		return
	fade_tween = create_tween()
	fade_tween.tween_property(active_player, "volume_db", SILENT_VOLUME_DB, fade_duration)
	fade_tween.finished.connect(_finish_stop.bind(version), CONNECT_ONE_SHOT)


func _finish_crossfade(previous_player: AudioStreamPlayer, version: int) -> void:
	if version != transition_version:
		return
	previous_player.stop()
	previous_player.stream = null


func _finish_stop(version: int) -> void:
	if version != transition_version:
		return
	for player in players:
		player.stop()
		player.stream = null


func _set_stream_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
