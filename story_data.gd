class_name StoryData
extends RefCounted

## ゲーム内ストーリーの本文と、会話終了後の遷移先を一括管理する。
## 各ページは speaker、speaker_id、text、characters を持つ。
## charactersへ {"id": キャラクターID, "expression": 表情名} を並べると、人数に応じて立ち位置が自動調整される。

const PROLOGUE_PAGES: Array[Dictionary] = [
	{"speaker": "", "speaker_id": "", "text": "魔法少女の朝は、魔力の補給から始まる。\n今日も街のどこかで、エネルギーが生まれている。", "characters": [{"id": "bio", "expression": "default"}]},
	{"speaker": "ばいお", "speaker_id": "bio", "text": "この世の魔力はすべて私のもの！\n他の魔法少女には与えないわ！", "characters": [{"id": "bio", "expression": "emphasis"}, {"id": "mascot", "expression": "default"}]},
	{"speaker": "マスコット", "speaker_id": "mascot", "text": "それなら、こっちが先に強奪えればいいんだね！", "characters": [{"id": "bio", "expression": "default"}, {"id": "mascot", "expression": "default"}]},
	{"speaker": "ばいお", "speaker_id": "bio", "text": "そう！ 魔力は取り合い、チャンスは奪い合い！", "characters": [{"id": "bio", "expression": "gesture"}, {"id": "mascot", "expression": "default"}]},
	{"speaker": "ばいお", "speaker_id": "bio", "text": "なのに、\"ぎふと\"とかいう魔法少女が皆に魔力を分け与えているわ！許せん！", "characters": [{"id": "bio", "expression": "gesture"}, {"id": "mascot", "expression": "default"}]},
	{"speaker": "", "speaker_id": "", "text": "こうして、魔法少女の強奪戦が幕を開ける。\n強奪え！ 魔法少女ばいお！", "characters": [{"id": "bio", "expression": "default"}, {"id": "mascot", "expression": "default"}]}
]

const BATTLE_STORY_PAGES: Array = [
	[
		{"speaker": "", "speaker_id": "", "text": "スライムの魔力を奪った。\n微々たるものだが無いよりはマシだろう。", "characters": [{"id": "bio", "expression": "emphasis"}]},
		{"speaker": "ばいお", "speaker_id": "bio", "text": "次はもっと大きな獲物よ。\n他の魔法少女に勝つために魔力を集めるわ！", "characters": [{"id": "bio", "expression": "emphasis"}]}
	],
	[
		{"speaker": "ばいお", "speaker_id": "bio", "text": "なんか力を蓄えてた不審者を倒したわ！", "characters": [{"id": "bio", "expression": "default"}]},
		{"speaker": "", "speaker_id": "", "text": "更なる力を得たばいお。\n宿敵、魔法少女ぎふととの戦いは近い。", "characters": [{"id": "bio", "expression": "default"}]}
	]
]

const ENDING_PAGES: Array[Dictionary] = [
	{"speaker": "ばいお", "speaker_id": "bio", "text": "魔法少女ぎふとを倒して、魔力をばら撒くお邪魔虫はいなくなったわ！", "characters": [{"id": "bio", "expression": "default"}, {"id": "mascot", "expression": "default"}]},
	{"speaker": "マスコット", "speaker_id": "mascot", "text": "これで街の魔力はみんなばいおのものだね！", "characters": [{"id": "bio", "expression": "emphasis"}, {"id": "mascot", "expression": "default"}]},
	{"speaker": "", "speaker_id": "", "text": "強奪え！ 魔法少女ばいお！\n……次の魔力が生まれるまで、しばらく休もう。", "characters": [{"id": "bio", "expression": "gesture"}, {"id": "mascot", "expression": "default"}]}
]

const NEXT_SCENES := {
	"prologue": "res://battle_prep.tscn",
	"story": "res://battle_prep.tscn",
	"ending": "res://title_screen.tscn"
}


static func get_pages(story_id: String, progress_index: int = 0) -> Array[Dictionary]:
	var source: Array = []
	match story_id:
		"prologue":
			source = PROLOGUE_PAGES
		"story":
			if progress_index < 0 or progress_index >= BATTLE_STORY_PAGES.size():
				return []
			source = BATTLE_STORY_PAGES[progress_index]
		"ending":
			source = ENDING_PAGES
		_:
			return []

	var result: Array[Dictionary] = []
	for entry: Variant in source:
		if entry is Dictionary:
			result.append((entry as Dictionary).duplicate(true))
	return result


static func get_next_scene(story_id: String) -> String:
	return str(NEXT_SCENES.get(story_id, ""))
