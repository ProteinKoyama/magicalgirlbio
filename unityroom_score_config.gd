class_name UnityroomScoreConfig
extends RefCounted

# unityroomのゲーム管理画面で発行したHMACキーを設定してください。
# 未設定の間はスコア送信を行わず、ゲーム本編はそのまま進行します。
const HMAC_KEY: String = ""

# unityroom側で作成したランキングのボード番号です。
# 総ラウンド数は少ないほど上位になるため、ランキングの並び順は昇順にしてください。
const SCOREBOARD_ID: int = 1
