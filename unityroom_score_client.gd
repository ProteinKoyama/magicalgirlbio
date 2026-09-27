extends Node

const ScoreConfig = preload("res://unityroom_score_config.gd")

var _client: UnityroomClient
var _submitted_this_run: bool = false


func _ready() -> void:
	_create_client_if_configured()


func reset_run() -> void:
	_submitted_this_run = false


func submit_total_rounds(total_rounds: int) -> void:
	if _submitted_this_run:
		return
	if total_rounds <= 0:
		push_warning("unityroomへ送信する総ラウンド数が不正です: %d" % total_rounds)
		return
	if ScoreConfig.HMAC_KEY.is_empty():
		push_warning("unityroomのHMACキーが未設定のため、総ラウンド数の送信をスキップしました。")
		return
	if _client == null:
		_create_client_if_configured()
	if _client == null:
		push_warning("unityroomクライアントを初期化できなかったため、スコアを送信できませんでした。")
		return

	_submitted_this_run = true
	_client.send_score(ScoreConfig.SCOREBOARD_ID, float(total_rounds))


func _create_client_if_configured() -> void:
	if _client != null or ScoreConfig.HMAC_KEY.is_empty():
		return
	_client = UnityroomClient.new(ScoreConfig.HMAC_KEY)
	_client.score_uploaded.connect(_on_score_uploaded)
	add_child(_client)


func _on_score_uploaded(success: bool, response: UnityroomClient.Response) -> void:
	if success:
		var upload_response: UnityroomClient.ScoreUploadResponse = response as UnityroomClient.ScoreUploadResponse
		print("unityroomへ総ラウンド数を送信しました。ランキング更新: %s" % str(upload_response.score_updated))
		return

	var error_response: UnityroomClient.ErrorResponse = response as UnityroomClient.ErrorResponse
	if error_response != null:
		push_warning("unityroomへのスコア送信に失敗しました: %s" % error_response.message)
	else:
		push_warning("unityroomへのスコア送信に失敗しました。")
