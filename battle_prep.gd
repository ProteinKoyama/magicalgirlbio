extends Control

const BATTLE_PREP_BGM: AudioStream = preload("res://Assets/MusMus-BGM-141.mp3")
const SKILL_DETAIL_POPUP_SIZE := Vector2i(1000, 600)

@onready var enemy_name: Label = $LoadoutArea/EnemyInfo/MarginContainer/VBoxContainer/Name
@onready var enemy_hp: Label = $LoadoutArea/EnemyInfo/MarginContainer/VBoxContainer/HP
@onready var enemy_description: Label = $LoadoutArea/EnemyInfo/MarginContainer/VBoxContainer/Description
@onready var enemy_actions: Label = $LoadoutArea/EnemyInfo/MarginContainer/VBoxContainer/Actions
@onready var skill_option: OptionButton = $LoadoutArea/EquippedSkills/MarginContainer/VBoxContainer/SkillOption
@onready var attack_trait_option: OptionButton = $LoadoutArea/EquippedSkills/MarginContainer/VBoxContainer/AttackTraitOption
@onready var skill_trait_option: OptionButton = $LoadoutArea/EquippedSkills/MarginContainer/VBoxContainer/SkillTraitOption
@onready var charge_trait_option: OptionButton = $LoadoutArea/EquippedSkills/MarginContainer/VBoxContainer/ChargeTraitOption
@onready var available_skill_list: ItemList = $LoadoutArea/AvailableSkills/MarginContainer/VBoxContainer/SkillList
@onready var start_button: BaseButton = $StartButton
@onready var skill_detail_popup: PopupPanel = $SkillDetailPopup
@onready var skill_detail_name: Label = $SkillDetailPopup/MarginContainer/VBoxContainer/SkillName
@onready var skill_detail_description: Label = $SkillDetailPopup/MarginContainer/VBoxContainer/SkillDescription
@onready var skill_detail_close_button: TextureButton = $SkillDetailPopup/MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
	BgmManager.play_bgm(BATTLE_PREP_BGM)
	skill_detail_popup.min_size = SKILL_DETAIL_POPUP_SIZE
	skill_detail_popup.max_size = SKILL_DETAIL_POPUP_SIZE
	skill_detail_popup.size = SKILL_DETAIL_POPUP_SIZE
	var data := GameFlow.current_battle()
	enemy_name.text = data["name"]
	enemy_hp.text = "HP %d" % data["hp"]
	enemy_description.text = data["description"]
	enemy_actions.text = "攻撃力：%d\n必殺ゲージ：%d\n取得優先度：%s\nスキル：%s\n必殺技：%s" % [
		int(data["attack"]),
		int(data["charge_max"]),
		str(data["priority_text"]),
		str(data["actions"][0]),
		str(data["actions"][1])
	]
	_setup_option(skill_option, GameFlow.unlocked_skills, GameFlow.selected_skill)
	_setup_option(attack_trait_option, GameFlow.AVAILABLE_TRAITS, GameFlow.selected_traits["attack"])
	_setup_option(skill_trait_option, GameFlow.AVAILABLE_TRAITS, GameFlow.selected_traits["skill"])
	_setup_option(charge_trait_option, GameFlow.AVAILABLE_TRAITS, GameFlow.selected_traits["charge"])
	_set_list_items(available_skill_list, GameFlow.unlocked_skills)
	skill_option.item_selected.connect(_on_skill_selected)
	attack_trait_option.item_selected.connect(_on_trait_selected.bind("attack", attack_trait_option))
	skill_trait_option.item_selected.connect(_on_trait_selected.bind("skill", skill_trait_option))
	charge_trait_option.item_selected.connect(_on_trait_selected.bind("charge", charge_trait_option))
	available_skill_list.item_selected.connect(_on_available_skill_selected)
	available_skill_list.item_clicked.connect(_on_available_skill_clicked)
	skill_detail_close_button.pressed.connect(skill_detail_popup.hide)
	start_button.pressed.connect(GameFlow.start_next_battle)

func _setup_option(option: OptionButton, items: Array, selected: String) -> void:
	option.clear()
	option.get_popup().add_theme_font_size_override("font_size", 24)
	for item in items:
		option.add_item(str(item))
	var selected_index := items.find(selected)
	option.select(maxi(0, selected_index))

func _on_skill_selected(index: int) -> void:
	GameFlow.selected_skill = skill_option.get_item_text(index)

func _on_trait_selected(index: int, action: String, option: OptionButton) -> void:
	GameFlow.selected_traits[action] = option.get_item_text(index)

func _on_available_skill_selected(index: int) -> void:
	if index < 0 or index >= available_skill_list.item_count:
		return
	_show_skill_detail(available_skill_list.get_item_text(index))

func _on_available_skill_clicked(index: int, _position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	if index < 0 or index >= available_skill_list.item_count:
		return
	_show_skill_detail(available_skill_list.get_item_text(index))

func _show_skill_detail(skill_name: String) -> void:
	if skill_detail_popup.visible:
		return
	skill_detail_name.text = skill_name
	skill_detail_description.text = str(GameFlow.SKILL_DESCRIPTIONS.get(
		skill_name,
		"このスキルの性能はまだ登録されていません。"
	))
	_popup_at_fixed_size(skill_detail_popup, SKILL_DETAIL_POPUP_SIZE)

func _popup_at_fixed_size(popup: Popup, popup_size: Vector2i) -> void:
	var viewport_size: Vector2i = Vector2i(get_viewport_rect().size)
	var popup_position: Vector2i = (viewport_size - popup_size) / 2
	popup.min_size = popup_size
	popup.max_size = popup_size
	popup.popup(Rect2i(popup_position, popup_size))
	popup.size = popup_size

func _set_list_items(list: ItemList, items: Array) -> void:
	list.clear()
	for item in items:
		list.add_item(str(item))
