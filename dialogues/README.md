# 会話データ

会話表示はすべて `res://dialogue.tscn` と `res://dialogue.gd` を使用します。
現在のシナリオ本文は `dialogue.gd` の定数として管理します。JSONファイルは使用しません。
プロローグ、ストーリーパート、エンディングごとのシーン複製は不要です。

シナリオを追加する場合は、`dialogue.gd` にページ配列とシナリオIDを追加します。

- `title`: 管理用の任意のタイトル（画面には表示しません）
- `next_scene`: 読了・スキップ後の遷移先（存在するtscnのres://パス）
- `pages`: `speaker`（話者名）、`text`（本文）、任意の `portrait`（立ち絵差分名）を持つページの配列

`portrait` には `default`、`emphasis`、`gesture` を指定できます。
省略したページでは直前の立ち絵を維持し、`hide` を指定すると立ち絵を非表示にします。

本文内の改行は `\n` で指定します。現在のプロローグは `dialogue.gd` 内に実装されています。
ダイアログ内のクリックまたはEnterキーで次のページへ進み、最終ページの次に遷移先へ移動します。

呼び出し例:

```gdscript
const DialogueScene = preload("res://dialogue.gd")

func start_story() -> void:
    DialogueScene.play(get_tree(), "prologue")
```

別パートを追加するときは、そのパートのJSONと実際の遷移先を用意し、渡すJSONパスを変更します。
エディターで共通シーンを直接実行する場合は、ルートの `Dialogue Path` でJSONを指定できます。
エクスポート時には、会話JSONが出力に含まれるように設定してください。
