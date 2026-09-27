extends Node

const DialogueScene = preload("res://dialogue.gd")
const SLIME_TEXTURE: Texture2D = preload("res://Assets/slime.png")
const ANGELN_TEXTURE: Texture2D = preload("res://Assets/angeln.png")
const GIFT_TEXTURE: Texture2D = preload("res://Assets/gift_common.png")

var battle_index := 0
var story_index := 0
var total_rounds := 0
var best_rounds_by_battle: Dictionary = {}
var selected_skill := "強奪"
var selected_traits := {
	"attack": "なし",
	"skill": "なし",
	"charge": "なし"
}
var unlocked_skills := ["強奪", "猛毒", "スキルチャージ"]

const AVAILABLE_TRAITS := [
	"なし",
	"必殺チャージ＋1追加",
	"HP5回復",
	"通常攻撃を一回追加"
]

const TRAIT_DESCRIPTIONS := {
	"なし": "追加効果はありません",
	"必殺チャージ＋1追加": "対応する行動後に、自分の必殺チャージをさらに1増加する",
	"HP5回復": "対応する行動後に、自分のHPを5回復する",
	"通常攻撃を一回追加": "対応する行動後に、敵へ通常攻撃をもう一回行う"
}

const SKILL_DESCRIPTIONS := {
	"強奪": "敵に5ダメージを与え、敵の必殺チャージを1奪う",
	"猛毒": "敵を猛毒状態にし、ラウンド終了時に2＋経過ターン数のダメージを与える。すでに猛毒の場合は重複しない",
	"スキルチャージ": "自分の必殺チャージを2増加する",
	"魔力吸収": "敵の必殺チャージを2減らし、自分の必殺チャージを1増加する",
	"吸血": "相手に５ダメージを与えて3回復",
	"バリア": "次に受ける1回分のダメージを無効化する。毒ダメージも防ぐ。有効中は重ねがけできない"
}

const BATTLES := [
	{"name": "スライム", "hp": 20, "player_hp": 50, "portrait": SLIME_TEXTURE, "description": "魔力吸収：相手の必殺チャージを2減らし、自分の必殺チャージを1増やす。\n体当たり：相手に10ダメージ。", "actions": ["魔力吸収", "体当たり"], "skill_description": "相手の必殺チャージを2減らし、自分の必殺チャージを1増やす", "special_description": "相手に10ダメージを与える", "priority_text": "攻撃（無い場合はランダム）", "priority": ["attack"], "attack": 5, "skill_id": "mana_absorb", "charge": 2, "charge_max": 8, "special_id": "body_slam", "reward_skill": "魔力吸収", "story_after": true},
	{"name": "コウモリ男", "hp": 50, "player_hp": 50, "description": "吸血：相手に５ダメージを与えて3回復。\n再生：自分のHPを全回復。", "actions": ["吸血", "再生"], "skill_description": "相手に５ダメージを与えて3回復", "special_description": "自分のHPを全回復する", "priority_text": "スキル ＞ チャージ ＞ 攻撃", "priority": ["skill", "charge", "attack"], "attack": 10, "skill_id": "vampire", "charge": 2, "charge_max": 10, "special_id": "regeneration", "reward_skill": "吸血", "story_after": true},
	{"name": "えんじぇるん", "hp": 80, "player_hp": 50, "portrait": ANGELN_TEXTURE, "description": "バリア：1回だけダメージを無効化する（毒ダメージも防ぐ）。有効中は重ねがけできない。\nエンジェルアロー：相手に30ダメージを与え、自分のHPを10回復する。", "actions": ["バリア", "エンジェルアロー"], "skill_description": "次に受ける1回分のダメージを無効化する。毒ダメージも防ぐ。有効中は重ねがけできない", "special_description": "相手に30ダメージを与え、自分のHPを10回復する", "priority_text": "スキル ＞ チャージ ＞ 攻撃", "priority": ["skill", "charge", "attack"], "attack": 8, "skill_id": "barrier", "charge": 2, "charge_max": 8, "special_id": "angel_arrow", "reward_skill": "バリア", "story_after": true},
	{"name": "魔法少女ぎふと", "hp": 100, "player_hp": 50, "portrait": GIFT_TEXTURE, "portrait_width": 500.0, "description": "プレゼント：自分のHPを10回復。\nデスギフト：相手に50ダメージ。", "actions": ["プレゼント", "デスギフト"], "skill_description": "自分のHPを10回復する", "special_description": "相手に50ダメージを与える", "priority_text": "チャージ ＞ スキル ＞ 攻撃", "priority": ["charge", "skill", "attack"], "attack": 10, "skill_id": "present", "charge": 2, "charge_max": 10, "special_id": "death_gift", "story_after": false}
]

const ENERGY_IMAGES := ["res://Assets/attack.png", "res://Assets/skill.png", "res://Assets/charge.png"]

func reset_run() -> void:
	battle_index = 0
	story_index = 0
	total_rounds = 0
	best_rounds_by_battle.clear()
	UnityroomScoreClient.reset_run()
	selected_skill = "強奪"
	selected_traits = {"attack": "なし", "skill": "なし", "charge": "なし"}
	unlocked_skills = ["強奪", "猛毒", "スキルチャージ"]

func current_battle() -> Dictionary:
	return BATTLES[clampi(battle_index, 0, BATTLES.size() - 1)]

func start_next_battle() -> void:
	SceneTransition.change_scene_to_file("res://battle.tscn")

func record_battle_victory(round_count: int) -> void:
	var cleared_rounds: int = maxi(round_count, 1)
	var previous_best: int = int(best_rounds_by_battle.get(battle_index, 0))
	if previous_best == 0 or cleared_rounds < previous_best:
		best_rounds_by_battle[battle_index] = cleared_rounds

	total_rounds = 0
	for recorded_rounds: Variant in best_rounds_by_battle.values():
		total_rounds += int(recorded_rounds)

	if battle_index == BATTLES.size() - 1:
		if best_rounds_by_battle.size() == BATTLES.size():
			UnityroomScoreClient.submit_total_rounds(total_rounds)
		else:
			push_warning("全ステージの最短ラウンド数が揃っていないため、unityroomへの送信をスキップしました。")

func finish_battle() -> void:
	var data := current_battle()
	var reward_skill: String = data.get("reward_skill", "")
	if not reward_skill.is_empty() and not unlocked_skills.has(reward_skill):
		unlocked_skills.append(reward_skill)
	battle_index += 1
	if data["story_after"]:
		story_index = battle_index - 1
		DialogueScene.requested_dialogue_path = "story"
		SceneTransition.change_scene_to_file("res://dialogue.tscn")
	else:
		DialogueScene.requested_dialogue_path = "ending"
		SceneTransition.change_scene_to_file("res://dialogue.tscn")

func finish_story() -> void:
	SceneTransition.change_scene_to_file("res://battle_prep.tscn")
