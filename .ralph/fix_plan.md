# Fix Plan (タスクバックログ)

<!--
初回 ralph-loop 実行時に Claude が SPEC.md / CLAUDE.md の完了条件から派生して埋めます。
以降は PROMPT.md の Step 1 で次のタスクを選ぶ参照元として使用。

タスクは Phase 単位 (例: Phase 1: ユーザー認証)。各 Phase に short slug を付与
(branch 名が claude/phase-{N}-{slug} の形式になる)。

完了時は [x] を付与し、`## 完了タスク` セクションに移動 (Step 5 の責務)。
-->

## Pending tasks

(初回は空。Claude が初回イテレーションで SPEC.md / CLAUDE.md から派生して列挙)

例:
- [ ] Phase 1: ユーザー認証 (slug: `user-auth`)
- [ ] Phase 2: DB スキーマ (slug: `db-schema`)
- [ ] Phase 3: API エンドポイント (slug: `api-endpoints`)
- [ ] Phase 4: テストカバレッジ強化 (slug: `test-coverage`)

## 完了タスク

(初回は空)
