extends Control

signal hp_change_queue_finished

const BATTLE_BGM: AudioStream = preload("res://Assets/MusMus-BGM-167.mp3")
const ENERGY_ATTACK := "attack"
const ENERGY_SKILL := "skill"
const ENERGY_CHARGE := "charge"
const ENERGY_TYPES := [ENERGY_ATTACK, ENERGY_SKILL, ENERGY_CHARGE]
const ENERGY_NAMES := {
	ENERGY_ATTACK: "攻撃魔力",
	ENERGY_SKILL: "スキル魔力",
	ENERGY_CHARGE: "チャージ魔力"
}
const MAX_CHARGE := 10
const PLAYER_ATTACK_DAMAGE := 5
const PLAYER_SKILL_DAMAGE := 5
const PLAYER_SPECIAL_DAMAGE := 40
const VAMPIRE_DAMAGE := 5
const VAMPIRE_CHARGE_GAIN := 1
const BASE_CHARGE_GAIN := 2
const ENEMY_PORTRAIT_WIDTH := 600.0
const ENEMY_DEFEAT_ANIMATION_FRAMES := 60
const ENEMY_DEFEAT_SHAKE_DISTANCE := 5.0
const ENEMY_DETAIL_POPUP_SIZE := Vector2i(880, 560)
const PLAYER_DETAIL_POPUP_SIZE := Vector2i(980, 800)
const HP_CHANGE_POPUP_SIZE := Vector2(220, 90)
const HP_CHANGE_POPUP_GAP := 12.0
const HP_CHANGE_POPUP_FAST_MOVE_DURATION := 0.2
const HP_CHANGE_POPUP_FAST_FADE_DURATION := 0.15
const HP_CHANGE_POPUP_FAST_HOLD_DURATION := 0.4
const DAMAGE_RECOIL_DISTANCE := 10.0
const DAMAGE_RECOIL_FRAME_DURATION := 1.0 / 60.0
const HP_DAMAGE_COLOR := Color(1.0, 0.12, 0.12)
const HP_RECOVERY_COLOR := Color(0.1, 1.0, 0.2)

@onready var title: Label = $Title
@onready var round_info: Label = $RoundInfo
@onready var player_portrait: AnimatedSprite2D = $Player/AnimatedSprite2D
@onready var player_click_area: Button = $PlayerClickArea
@onready var player_barrier_icon: TextureRect = $Player/NameRow/BarrierIcon
@onready var player_hp_text: Label = $Player/HPText
@onready var player_hp_bar: ProgressBar = $Player/HP
@onready var player_charge_text: Label = $Player/ChargeText
@onready var player_charge_bar: ProgressBar = $Player/Charge
@onready var enemy_name: Label = $Enemy/NameRow/Name
@onready var enemy_poison_icon: TextureRect = $Enemy/NameRow/StatusIcons/PoisonIcon
@onready var enemy_barrier_icon: TextureRect = $Enemy/NameRow/StatusIcons/BarrierIcon
@onready var enemy_portrait: TextureRect = $Enemy/Portrait
@onready var enemy_hp_text: Label = $Enemy/HPText
@onready var enemy_hp_bar: ProgressBar = $Enemy/HP
@onready var enemy_charge_text: Label = $Enemy/ChargeText
@onready var enemy_charge_bar: ProgressBar = $Enemy/Charge
@onready var instruction: Label = $Instruction
@onready var energy_container: VBoxContainer = $Energy
@onready var energy_buttons: Array[TextureButton] = [$Energy/Energy1, $Energy/Energy2, $Energy/Energy3, $Energy/Energy4, $Energy/Energy5]
@onready var selection_detail: PanelContainer = $SelectionDetail
@onready var selection_detail_title: Label = $SelectionDetail/MarginContainer/VBoxContainer/Title
@onready var selection_detail_description: Label = $SelectionDetail/MarginContainer/VBoxContainer/Description
@onready var victory_display: VBoxContainer = $VictoryDisplay
@onready var continue_button: TextureButton = $VictoryDisplay/NextButton
@onready var reward_popup: Control = $RewardPopup
@onready var reward_message: Label = $RewardPopup/Panel/Content/Message
@onready var reward_next_button: TextureButton = $RewardPopup/Panel/Content/NextButton
@onready var defeat_display: VBoxContainer = $DefeatDisplay
@onready var retry_button: TextureButton = $DefeatDisplay/RetryButton
@onready var battle_retry_button: TextureButton = $BattleRetryButton
@onready var debug_win_button: Button = $DebugWinButton
@onready var retry_confirmation: Control = $RetryConfirmation
@onready var retry_confirmation_button: TextureButton = $RetryConfirmation/Panel/Content/Buttons/RetryButton
@onready var retry_cancel_button: TextureButton = $RetryConfirmation/Panel/Content/Buttons/CancelButton
@onready var enemy_detail_popup: PopupPanel = $EnemyDetailPopup
@onready var enemy_detail_name: Label = $EnemyDetailPopup/MarginContainer/VBoxContainer/EnemyName
@onready var enemy_detail_description: Label = $EnemyDetailPopup/MarginContainer/VBoxContainer/Description
@onready var enemy_detail_close_button: TextureButton = $EnemyDetailPopup/MarginContainer/VBoxContainer/CloseButton
@onready var player_detail_popup: PopupPanel = $PlayerDetailPopup
@onready var player_detail_description: Label = $PlayerDetailPopup/MarginContainer/VBoxContainer/DescriptionScroll/Description
@onready var player_detail_close_button: TextureButton = $PlayerDetailPopup/MarginContainer/VBoxContainer/CloseButton
@onready var attack_se_player: AudioStreamPlayer = $AttackSePlayer
@onready var bomb_se_player: AudioStreamPlayer = $BombSePlayer
@onready var charge_se_player: AudioStreamPlayer = $ChargeSePlayer
@onready var mahou_se_player: AudioStreamPlayer = $MahouSePlayer
@onready var orbup_se_player: AudioStreamPlayer = $OrbUpSePlayer
@onready var player_special_effect: BattleSpecialEffect = $PlayerSpecialEffect

var player_max_hp := 50
var player_hp := 50
var player_charge := 0
var enemy_max_hp := 10
var enemy_hp := 10
var enemy_charge := 0
var enemy_charge_max := 8
var round_number := 1
var first_actor := "player"
var current_actor := "player"
var picks_taken := 0
var selected_energy_index := -1
var energy_highlight_tween: Tween
var energy_types: Array[String] = []
var battle_finished := false
var battle_data: Dictionary = {}
var enemy_is_poisoned := false
var enemy_barrier_active := false
var player_barrier_active := false
var poison_elapsed_turns := 0
var player_animation_version := 0
var hp_change_queue: Array[Dictionary] = []
var hp_change_queue_active := false
var damage_recoil_home_positions: Dictionary = {}
var damage_recoil_tweens: Dictionary = {}
var retry_confirmation_open := false
var enemy_detail_open := false
var player_detail_open := false

func _ready() -> void:
	BgmManager.play_bgm(BATTLE_BGM)
	enemy_detail_popup.min_size = ENEMY_DETAIL_POPUP_SIZE
	enemy_detail_popup.max_size = ENEMY_DETAIL_POPUP_SIZE
	enemy_detail_popup.size = ENEMY_DETAIL_POPUP_SIZE
	player_detail_popup.min_size = PLAYER_DETAIL_POPUP_SIZE
	player_detail_popup.max_size = PLAYER_DETAIL_POPUP_SIZE
	player_detail_popup.size = PLAYER_DETAIL_POPUP_SIZE
	randomize()
	var data := GameFlow.current_battle()
	battle_data = data
	player_max_hp = int(data["player_hp"])
	player_hp = player_max_hp
	enemy_max_hp = int(data["hp"])
	enemy_hp = enemy_max_hp
	enemy_charge_max = int(data.get("charge_max", MAX_CHARGE))
	title.text = "第%d戦　%sとの戦闘" % [GameFlow.battle_index + 1, data["name"]]
	enemy_name.text = data["name"]
	var enemy_texture: Variant = data.get("portrait")
	if enemy_texture is Texture2D:
		var portrait_texture: Texture2D = enemy_texture as Texture2D
		enemy_portrait.texture = portrait_texture
		var texture_size: Vector2 = portrait_texture.get_size()
		if texture_size.x > 0.0:
			var portrait_width: float = float(data.get("portrait_width", ENEMY_PORTRAIT_WIDTH))
			var portrait_height: float = portrait_width * texture_size.y / texture_size.x
			enemy_portrait.custom_minimum_size = Vector2(portrait_width, portrait_height)
	for i in energy_buttons.size():
		energy_buttons[i].pressed.connect(_on_energy_pressed.bind(i))
	continue_button.pressed.connect(GameFlow.finish_battle)
	reward_next_button.pressed.connect(GameFlow.finish_battle)
	retry_button.pressed.connect(_retry_battle)
	battle_retry_button.pressed.connect(_open_retry_confirmation)
	debug_win_button.visible = OS.is_debug_build()
	debug_win_button.pressed.connect(_debug_instant_win)
	retry_confirmation_button.pressed.connect(_retry_battle)
	retry_cancel_button.pressed.connect(_close_retry_confirmation)
	enemy_portrait.gui_input.connect(_on_enemy_portrait_gui_input)
	enemy_detail_close_button.pressed.connect(enemy_detail_popup.hide)
	enemy_detail_popup.popup_hide.connect(_on_enemy_detail_popup_hide)
	player_click_area.pressed.connect(_show_player_detail)
	player_detail_close_button.pressed.connect(player_detail_popup.hide)
	player_detail_popup.popup_hide.connect(_on_player_detail_popup_hide)
	_play_player_animation(&"default")
	_update_status()
	_start_round()

func _start_round() -> void:
	if battle_finished:
		return
	picks_taken = 0
	selected_energy_index = -1
	current_actor = first_actor
	energy_types.clear()
	for i in energy_buttons.size():
		var energy_type: String = ENERGY_TYPES[randi_range(0, ENERGY_TYPES.size() - 1)]
		energy_types.append(energy_type)
		var button := energy_buttons[i]
		button.texture_normal = load(GameFlow.ENERGY_IMAGES[ENERGY_TYPES.find(energy_type)])
		button.visible = true
		button.disabled = true
		button.modulate = Color(1.0, 1.0, 1.0, 0.0)
	round_info.text = "ラウンド %d　%s先攻" % [round_number, _actor_name(first_actor)]
	await _animate_round_energies()
	if battle_finished:
		return
	_begin_actor_pick()

func _animate_round_energies() -> void:
	await get_tree().process_frame
	var target_positions: Array[Vector2] = []
	for button: TextureButton in energy_buttons:
		target_positions.append(button.position)
		button.position += Vector2(0.0, 60.0)
		button.modulate.a = 0.0
	if not energy_buttons.is_empty():
		orbup_se_player.play()

	var appearance_tweens: Array[Tween] = []
	for i in energy_buttons.size():
		var button: TextureButton = energy_buttons[i]
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "position", target_positions[i], 0.3)
		tween.parallel().tween_property(button, "modulate:a", 1.0, 0.3)
		appearance_tweens.append(tween)
		if i < energy_buttons.size() - 1:
			await get_tree().create_timer(0.08).timeout

	if not appearance_tweens.is_empty():
		await appearance_tweens.back().finished

func _begin_actor_pick() -> void:
	selected_energy_index = -1
	_reset_energy_highlight()
	if current_actor == "player":
		_set_energy_buttons_enabled(true)
		instruction.text = "欲しい魔力をクリックし、もう一度クリックして確定"
	else:
		_set_energy_buttons_enabled(false)
		instruction.text = "%sが魔力を選んでいます…" % enemy_name.text
		_enemy_pick_after_delay()

func _on_energy_pressed(index: int) -> void:
	if battle_finished or current_actor != "player" or not _is_energy_available(index):
		return
	if selected_energy_index != index:
		selected_energy_index = index
		_reset_energy_highlight()
		_start_energy_blink(index)
		instruction.text = "%sを選択中。もう一度クリックで確定" % ENERGY_NAMES[energy_types[index]]
		_show_energy_selection_detail(energy_types[index])
		return
	_take_energy(index, "player")

func _enemy_pick_after_delay() -> void:
	await get_tree().create_timer(0.7).timeout
	if battle_finished or current_actor != "enemy":
		return
	var index := _choose_enemy_energy()
	if index >= 0:
		_take_energy(index, "enemy")

func _choose_enemy_energy() -> int:
	var available: Array[int] = []
	for i in energy_types.size():
		if _is_energy_available(i):
			available.append(i)
	var priority: Array = battle_data.get("priority", [ENERGY_ATTACK, ENERGY_SKILL, ENERGY_CHARGE])
	for preferred_type in priority:
		for index in available:
			if energy_types[index] == preferred_type:
				return index
	if available.is_empty():
		return -1
	return available[randi_range(0, available.size() - 1)]

func _take_energy(index: int, actor: String) -> void:
	if not _is_energy_available(index):
		return
	var energy_type := energy_types[index]
	energy_types[index] = ""
	selected_energy_index = -1
	_reset_energy_highlight()
	selection_detail.hide()
	_set_energy_buttons_enabled(false)
	energy_buttons[index].visible = false
	await _animate_energy_to_actor(index, actor)
	energy_buttons[index].disabled = true
	await _apply_energy(actor, energy_type)
	_update_status()
	await _wait_for_hp_change_queue()
	if _check_battle_end():
		return
	picks_taken += 1
	if picks_taken >= energy_buttons.size():
		_apply_poison_at_round_end()
		_update_status()
		await _wait_for_hp_change_queue()
		if _check_battle_end():
			return
		instruction.text = "次のラウンドへ…"
		await get_tree().create_timer(0.7).timeout
		if battle_finished:
			return
		round_number += 1
		first_actor = _opposite_actor(first_actor)
		_start_round()
		return
	current_actor = _opposite_actor(current_actor)
	_begin_actor_pick()

func _animate_energy_to_actor(index: int, actor: String) -> void:
	var source := energy_buttons[index]
	var flying_energy := TextureRect.new()
	flying_energy.texture = source.texture_normal
	flying_energy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flying_energy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flying_energy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flying_energy.size = source.size
	flying_energy.pivot_offset = flying_energy.size * 0.5
	flying_energy.z_index = 100
	add_child(flying_energy)
	flying_energy.global_position = source.global_position

	var destination_center := _get_actor_portrait_rect(actor).get_center()
	var destination_position := destination_center - flying_energy.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(flying_energy, "global_position", destination_position, 0.45)
	tween.tween_property(flying_energy, "scale", Vector2(0.3, 0.3), 0.45)
	tween.tween_property(flying_energy, "modulate:a", 0.0, 0.45)
	await tween.finished
	flying_energy.queue_free()

func _apply_energy(actor: String, energy_type: String) -> void:
	if energy_type == ENERGY_CHARGE:
		charge_se_player.play()
	if actor == "player":
		if energy_type == ENERGY_ATTACK or energy_type == ENERGY_SKILL:
			_play_player_animation(&"attack", 0.65)
		match energy_type:
			ENERGY_ATTACK:
				_change_enemy_hp(-PLAYER_ATTACK_DAMAGE)
				_apply_trait(ENERGY_ATTACK)
			ENERGY_SKILL:
				_apply_player_skill()
				_apply_trait(ENERGY_SKILL)
			ENERGY_CHARGE:
				player_charge += BASE_CHARGE_GAIN
				_apply_trait(ENERGY_CHARGE)
		if player_charge >= MAX_CHARGE and enemy_hp > 0:
			player_charge -= MAX_CHARGE
			_play_player_animation(&"attack", 0.8)
			mahou_se_player.play()
			await player_special_effect.play_effect(enemy_portrait.get_global_rect().get_center())
			_change_enemy_hp(-PLAYER_SPECIAL_DAMAGE, false)
	else:
		match energy_type:
			ENERGY_ATTACK:
				var damage: int = int(battle_data.get("attack", 2))
				_change_player_hp(-damage)
			ENERGY_SKILL:
				_apply_enemy_skill()
			ENERGY_CHARGE:
				var charge_gain: int = int(battle_data.get("charge", BASE_CHARGE_GAIN))
				enemy_charge += charge_gain
		if enemy_charge >= enemy_charge_max and player_hp > 0:
			enemy_charge -= enemy_charge_max
			_apply_enemy_special()

func _apply_enemy_skill() -> void:
	match str(battle_data.get("skill_id", "")):
		"mana_absorb":
			var stolen_charge := mini(2, player_charge)
			player_charge -= stolen_charge
			enemy_charge += 1
		"vampire":
			_change_player_hp(-VAMPIRE_DAMAGE)
			enemy_charge += VAMPIRE_CHARGE_GAIN
		"present":
			_change_enemy_hp(10)
		"barrier":
			if not enemy_barrier_active:
				enemy_barrier_active = true
				enemy_barrier_icon.show()

func _apply_enemy_special() -> void:
	match str(battle_data.get("special_id", "")):
		"body_slam":
			_change_player_hp(-10)
		"regeneration":
			_change_enemy_hp(enemy_max_hp - enemy_hp)
		"death_gift":
			_change_player_hp(-50)
		"angel_arrow":
			_change_player_hp(-30)
			_change_enemy_hp(10)

func _apply_player_skill() -> void:
	match GameFlow.selected_skill:
		"強奪":
			_change_enemy_hp(-PLAYER_SKILL_DAMAGE)
			var stolen_charge := mini(1, enemy_charge)
			enemy_charge -= stolen_charge
			player_charge += stolen_charge
		"猛毒":
			_apply_poison_to_enemy()
		"スキルチャージ":
			player_charge += BASE_CHARGE_GAIN
		"魔力吸収":
			var stolen_charge := mini(2, enemy_charge)
			enemy_charge -= stolen_charge
			player_charge += 1
		"吸血":
			_change_enemy_hp(-VAMPIRE_DAMAGE)
			player_charge += VAMPIRE_CHARGE_GAIN
		"バリア":
			if not player_barrier_active:
				player_barrier_active = true
				player_barrier_icon.show()
		_:
			_change_enemy_hp(-PLAYER_SKILL_DAMAGE)

func _apply_trait(action: String) -> void:
	var equipped_trait: String = GameFlow.selected_traits.get(action, "なし")
	match equipped_trait:
		"必殺チャージ＋1追加":
			player_charge += 1
		"HP5回復":
			_change_player_hp(5)
		"通常攻撃を一回追加":
			_play_player_animation(&"attack", 0.65)
			_change_enemy_hp(-PLAYER_ATTACK_DAMAGE)

func _apply_poison_to_enemy() -> void:
	if enemy_is_poisoned:
		return
	enemy_is_poisoned = true
	poison_elapsed_turns = 0
	enemy_poison_icon.show()

func _apply_poison_at_round_end() -> void:
	if not enemy_is_poisoned or enemy_hp <= 0:
		return
	var poison_damage := 2 + poison_elapsed_turns
	_change_enemy_hp(-poison_damage, false)
	poison_elapsed_turns += 1

func _change_player_hp(amount: int) -> int:
	if amount < 0 and player_barrier_active:
		player_barrier_active = false
		player_barrier_icon.hide()
		return 0
	var previous_hp := player_hp
	player_hp = clampi(player_hp + amount, 0, player_max_hp)
	var actual_change := player_hp - previous_hp
	if actual_change < 0:
		attack_se_player.play()
		_play_damage_recoil("player")
		_play_player_animation(&"damaged", 0.75)
		_show_hp_change("player", actual_change, false)
	elif actual_change > 0:
		_show_hp_change("player", actual_change, true)
	return actual_change

func _change_enemy_hp(amount: int, play_attack_se: bool = true) -> int:
	if amount < 0 and enemy_barrier_active:
		enemy_barrier_active = false
		enemy_barrier_icon.hide()
		return 0
	var previous_hp := enemy_hp
	enemy_hp = clampi(enemy_hp + amount, 0, enemy_max_hp)
	var actual_change := enemy_hp - previous_hp
	if actual_change != 0:
		if actual_change < 0:
			_play_damage_recoil("enemy")
		if actual_change < 0 and play_attack_se:
			attack_se_player.play()
		_show_hp_change("enemy", actual_change, actual_change > 0)
	return actual_change

func _play_damage_recoil(actor: String) -> void:
	var portrait: CanvasItem = player_portrait if actor == "player" else enemy_portrait
	var portrait_id: int = portrait.get_instance_id()
	var home_position: Vector2 = damage_recoil_home_positions.get(portrait_id, portrait.get("position"))
	damage_recoil_home_positions[portrait_id] = home_position
	var active_tween: Variant = damage_recoil_tweens.get(portrait_id)
	if active_tween is Tween and (active_tween as Tween).is_valid():
		(active_tween as Tween).kill()
	portrait.set("position", home_position)
	var recoil_direction := -1.0 if actor == "player" else 1.0
	var recoil_position := home_position + Vector2(recoil_direction * DAMAGE_RECOIL_DISTANCE, 0.0)
	var tween := create_tween()
	damage_recoil_tweens[portrait_id] = tween
	tween.tween_property(portrait, "position", recoil_position, DAMAGE_RECOIL_FRAME_DURATION).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(portrait, "position", home_position, DAMAGE_RECOIL_FRAME_DURATION * 5.0).set_trans(Tween.TRANS_LINEAR)
	tween.finished.connect(func() -> void: damage_recoil_tweens.erase(portrait_id))

func _show_hp_change(actor: String, amount: int, is_recovery: bool) -> void:
	hp_change_queue.append({"actor": actor, "amount": amount, "is_recovery": is_recovery})
	if not hp_change_queue_active:
		hp_change_queue_active = true
		_set_energy_buttons_enabled(false)
		_process_hp_change_queue.call_deferred()

func _process_hp_change_queue() -> void:
	var shorten_displays := hp_change_queue.size() >= 2
	while not hp_change_queue.is_empty():
		var popup_data: Dictionary = hp_change_queue.pop_front()
		await _display_hp_change(
			str(popup_data["actor"]),
			int(popup_data["amount"]),
			bool(popup_data["is_recovery"]),
			shorten_displays
		)
	hp_change_queue_active = false
	hp_change_queue_finished.emit()

func _wait_for_hp_change_queue() -> void:
	if hp_change_queue_active:
		await hp_change_queue_finished

func _display_hp_change(actor: String, amount: int, is_recovery: bool, shorten_display: bool = false) -> void:
	var popup := Label.new()
	popup.text = "+%d" % amount if amount > 0 else str(amount)
	popup.custom_minimum_size = HP_CHANGE_POPUP_SIZE
	popup.size = HP_CHANGE_POPUP_SIZE
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if actor == "player" else HORIZONTAL_ALIGNMENT_RIGHT
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.z_index = 300
	popup.add_theme_font_size_override("font_size", 100)
	popup.add_theme_constant_override("outline_size", 8)
	popup.add_theme_color_override("font_outline_color", Color.BLACK)
	popup.add_theme_color_override("font_color", HP_RECOVERY_COLOR if is_recovery else HP_DAMAGE_COLOR)
	add_child(popup)

	var portrait_rect := _get_actor_portrait_rect(actor)
	var target_position := Vector2.ZERO
	if actor == "player":
		target_position = Vector2(portrait_rect.end.x + HP_CHANGE_POPUP_GAP, portrait_rect.get_center().y - popup.size.y * 0.5)
	else:
		target_position = Vector2(portrait_rect.position.x - popup.size.x - HP_CHANGE_POPUP_GAP, portrait_rect.get_center().y - popup.size.y * 0.5)
	popup.global_position = target_position + Vector2(0, 80)
	popup.modulate.a = 0.0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	var move_duration := HP_CHANGE_POPUP_FAST_MOVE_DURATION if shorten_display else 0.4
	var fade_duration := HP_CHANGE_POPUP_FAST_FADE_DURATION if shorten_display else 0.25
	var hold_duration := HP_CHANGE_POPUP_FAST_HOLD_DURATION if shorten_display else 1.35
	tween.tween_property(popup, "global_position", target_position, move_duration)
	tween.parallel().tween_property(popup, "modulate:a", 1.0, fade_duration)
	tween.tween_interval(hold_duration)
	tween.tween_property(popup, "modulate:a", 0.0, fade_duration)
	await tween.finished
	popup.queue_free()

func _get_actor_portrait_rect(actor: String) -> Rect2:
	if actor != "player":
		return enemy_portrait.get_global_rect()
	var frame_texture: Texture2D = player_portrait.sprite_frames.get_frame_texture(
		player_portrait.animation,
		player_portrait.frame
	)
	if frame_texture == null:
		return Rect2(player_portrait.global_position, Vector2.ZERO)
	var texture_size: Vector2 = frame_texture.get_size()
	var local_top_left: Vector2 = player_portrait.offset
	if player_portrait.centered:
		local_top_left -= texture_size * 0.5
	var first_corner: Vector2 = player_portrait.to_global(local_top_left)
	var opposite_corner: Vector2 = player_portrait.to_global(local_top_left + texture_size)
	var top_left: Vector2 = Vector2(
		minf(first_corner.x, opposite_corner.x),
		minf(first_corner.y, opposite_corner.y)
	)
	var portrait_rect: Rect2 = Rect2(top_left, (opposite_corner - first_corner).abs())
	var visible_portrait_rect: Rect2 = portrait_rect.intersection(get_viewport_rect())
	if visible_portrait_rect.has_area():
		return visible_portrait_rect
	return portrait_rect

func _play_player_animation(animation_name: StringName, duration: float = 0.0) -> void:
	if not player_portrait.sprite_frames.has_animation(animation_name):
		push_warning("プレイヤーの未登録アニメーションです: %s" % animation_name)
		return
	player_animation_version += 1
	var animation_version := player_animation_version
	player_portrait.play(animation_name)
	if animation_name == &"default" or duration <= 0.0:
		return
	await get_tree().create_timer(duration).timeout
	if animation_version == player_animation_version and not battle_finished:
		_play_player_animation(&"default")

func _check_battle_end() -> bool:
	if enemy_hp <= 0:
		_finish_battle(true)
		return true
	if player_hp <= 0:
		_finish_battle(false)
		return true
	return false

func _finish_battle(player_won: bool) -> void:
	if battle_finished:
		return
	battle_finished = true
	if player_won:
		GameFlow.record_battle_victory(round_number)
	if enemy_detail_popup.visible:
		enemy_detail_popup.hide()
	if player_detail_popup.visible:
		player_detail_popup.hide()
	_set_energy_buttons_enabled(false)
	battle_retry_button.hide()
	debug_win_button.hide()
	player_click_area.hide()
	energy_container.hide()
	instruction.hide()
	selection_detail.hide()
	if player_won:
		defeat_display.hide()
		bomb_se_player.play()
		await _play_enemy_defeat_animation()
		if GameFlow.battle_index < GameFlow.BATTLES.size() - 1:
			var reward_skill := str(battle_data.get("reward_skill", ""))
			reward_message.text = "%sの能力を強奪した！" % str(battle_data.get("name", "敵"))
			if not reward_skill.is_empty():
				reward_message.text += "\n獲得スキル：%s" % reward_skill
			reward_popup.show()
			reward_next_button.grab_focus()
		else:
			victory_display.show()
			continue_button.grab_focus()
	else:
		reward_popup.hide()
		victory_display.hide()
		defeat_display.show()

func _debug_instant_win() -> void:
	if battle_finished:
		return
	enemy_hp = 0
	_update_status()
	_finish_battle(true)

func _play_enemy_defeat_animation() -> void:
	var defeat_material: ShaderMaterial = enemy_portrait.material as ShaderMaterial
	if defeat_material == null:
		return
	for frame_index in ENEMY_DEFEAT_ANIMATION_FRAMES:
		var shake_direction: float = 1.0 if frame_index % 2 == 0 else -1.0
		defeat_material.set_shader_parameter(
			"shake_offset",
			shake_direction * ENEMY_DEFEAT_SHAKE_DISTANCE
		)
		var disappear_progress: float = float(frame_index + 1) / float(ENEMY_DEFEAT_ANIMATION_FRAMES)
		defeat_material.set_shader_parameter("disappear_progress", disappear_progress)
		await get_tree().process_frame
	defeat_material.set_shader_parameter("shake_offset", 0.0)
	defeat_material.set_shader_parameter("disappear_progress", 1.0)

func _open_retry_confirmation() -> void:
	if battle_finished or retry_confirmation_open:
		return
	retry_confirmation_open = true
	retry_confirmation.show()
	get_tree().paused = true

func _close_retry_confirmation() -> void:
	retry_confirmation.hide()
	retry_confirmation_open = false
	get_tree().paused = false

func _on_enemy_portrait_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	if battle_finished or retry_confirmation_open or enemy_detail_open or player_detail_open:
		return
	enemy_portrait.accept_event()
	_show_enemy_detail()

func _show_enemy_detail() -> void:
	var actions: Array = battle_data.get("actions", [])
	var skill_name: String = str(actions[0]) if actions.size() > 0 else "未登録"
	var special_name: String = str(actions[1]) if actions.size() > 1 else "未登録"
	enemy_detail_name.text = str(battle_data.get("name", "敵"))
	enemy_detail_description.text = "攻撃力：%dダメージ\n\nスキル「%s」\n%s\n\n必殺技「%s」\n%s" % [
		int(battle_data.get("attack", 0)),
		skill_name,
		str(battle_data.get("skill_description", "性能は登録されていません。")),
		special_name,
		str(battle_data.get("special_description", "性能は登録されていません。"))
	]
	enemy_detail_open = true
	_popup_at_fixed_size(enemy_detail_popup, ENEMY_DETAIL_POPUP_SIZE)

func _on_enemy_detail_popup_hide() -> void:
	if not enemy_detail_open:
		return
	enemy_detail_open = false

func _show_player_detail() -> void:
	if battle_finished or retry_confirmation_open or enemy_detail_open or player_detail_open:
		return
	var skill_name: String = GameFlow.selected_skill
	var attack_trait: String = str(GameFlow.selected_traits.get("attack", "なし"))
	var skill_trait: String = str(GameFlow.selected_traits.get("skill", "なし"))
	var charge_trait: String = str(GameFlow.selected_traits.get("charge", "なし"))
	player_detail_description.text = "攻撃力：%dダメージ\n\n選択中のスキル「%s」\n%s\n\n攻撃魔力の特性「%s」\n%s\n\nスキル魔力の特性「%s」\n%s\n\nチャージ魔力の特性「%s」\n%s\n\n必殺技\n必殺チャージ%dで発動し、敵に%dダメージを与える" % [
		PLAYER_ATTACK_DAMAGE,
		skill_name,
		str(GameFlow.SKILL_DESCRIPTIONS.get(skill_name, "性能は登録されていません。")),
		attack_trait,
		str(GameFlow.TRAIT_DESCRIPTIONS.get(attack_trait, "性能は登録されていません。")),
		skill_trait,
		str(GameFlow.TRAIT_DESCRIPTIONS.get(skill_trait, "性能は登録されていません。")),
		charge_trait,
		str(GameFlow.TRAIT_DESCRIPTIONS.get(charge_trait, "性能は登録されていません。")),
		MAX_CHARGE,
		PLAYER_SPECIAL_DAMAGE
	]
	player_detail_open = true
	_popup_at_fixed_size(player_detail_popup, PLAYER_DETAIL_POPUP_SIZE)

func _on_player_detail_popup_hide() -> void:
	if not player_detail_open:
		return
	player_detail_open = false

func _popup_at_fixed_size(popup: Popup, popup_size: Vector2i) -> void:
	var viewport_size: Vector2i = Vector2i(get_viewport_rect().size)
	var popup_position: Vector2i = (viewport_size - popup_size) / 2
	popup.min_size = popup_size
	popup.max_size = popup_size
	popup.popup(Rect2i(popup_position, popup_size))
	popup.size = popup_size

func _retry_battle() -> void:
	get_tree().paused = false
	retry_confirmation_open = false
	enemy_detail_open = false
	player_detail_open = false
	SceneTransition.change_scene_to_file("res://battle_prep.tscn")

func _exit_tree() -> void:
	if retry_confirmation_open:
		get_tree().paused = false

func _update_status() -> void:
	player_hp_bar.max_value = player_max_hp
	player_hp_bar.value = player_hp
	player_hp_text.text = "HP %d / %d" % [player_hp, player_max_hp]
	player_charge_bar.max_value = MAX_CHARGE
	player_charge_bar.value = player_charge
	player_charge_text.text = "必殺チャージ %d / %d" % [player_charge, MAX_CHARGE]
	enemy_hp_bar.max_value = enemy_max_hp
	enemy_hp_bar.value = enemy_hp
	enemy_hp_text.text = "HP %d / %d" % [enemy_hp, enemy_max_hp]
	enemy_charge_bar.max_value = enemy_charge_max
	enemy_charge_bar.value = enemy_charge
	enemy_charge_text.text = "必殺チャージ %d / %d" % [enemy_charge, enemy_charge_max]

func _set_energy_buttons_enabled(enabled: bool) -> void:
	for i in energy_buttons.size():
		energy_buttons[i].disabled = not enabled or hp_change_queue_active or not _is_energy_available(i)

func _reset_energy_highlight() -> void:
	if energy_highlight_tween != null and energy_highlight_tween.is_valid():
		energy_highlight_tween.kill()
	energy_highlight_tween = null
	for button in energy_buttons:
		button.modulate = Color.WHITE
	selection_detail.hide()

func _start_energy_blink(index: int) -> void:
	var selected_button: TextureButton = energy_buttons[index]
	energy_highlight_tween = create_tween().set_loops()
	energy_highlight_tween.tween_property(selected_button, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.25)
	energy_highlight_tween.tween_property(selected_button, "modulate", Color.WHITE, 0.25)

func _show_energy_selection_detail(energy_type: String) -> void:
	var equipped_trait: String = str(GameFlow.selected_traits.get(energy_type, "なし"))
	selection_detail_title.text = "%sの装備情報" % ENERGY_NAMES.get(energy_type, "魔力")
	if energy_type == ENERGY_SKILL:
		var skill_name: String = GameFlow.selected_skill
		var skill_description: String = str(GameFlow.SKILL_DESCRIPTIONS.get(
			skill_name,
			"このスキルの性能はまだ登録されていません。"
		))
		selection_detail_description.text = "装備中のスキル：%s\n%s\n装備中の特性：%s" % [
			skill_name,
			skill_description,
			equipped_trait
		]
	else:
		selection_detail_description.text = "装備中の特性：%s" % equipped_trait
	selection_detail.show()

func _is_energy_available(index: int) -> bool:
	return index >= 0 and index < energy_types.size() and not energy_types[index].is_empty()

func _opposite_actor(actor: String) -> String:
	return "enemy" if actor == "player" else "player"

func _actor_name(actor: String) -> String:
	return "プレイヤー" if actor == "player" else enemy_name.text
