# Ralph Loop State

<!--
このファイルは ralph-loop が毎イテレーション更新します。手動編集不要。
PROMPT.md の Step 0 / Step 5 の指示に従って Claude が維持します。

- メタ: ループ全体の進捗
- アクティブ PR: open 中の PR と CI 状態、fix_attempts カウント
- 完了タスク: merged 済タスクの履歴
- エスカレーション: 3 回連続 fix 失敗で issue 化された PR
-->

## メタ

- last_iteration: 0
- started_at: (初回起動時に Claude が ISO8601 で記入、例: `2026-04-30T15:00:00Z`)
- completed_at: null

## アクティブ PR

| PR# | Branch | Phase | CI status | fix_attempts | Notes |
|---|---|---|---|---|---|

(初回は空。PR 作成時に Step 5 で追加)

## 完了タスク

(初回は空。merged 確認時に Step 0 でここに移動)

## エスカレーション

(初回は空。fix_attempts >= 3 で Step 0-3 から記載)
