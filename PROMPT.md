# Ralph Loop Prompt

このファイルは [`/ralph-loop`](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/ralph-loop) で自律開発を実行するときに渡すプロンプトです。

VPS 上の devcontainer 内で `claude` を起動した後、以下のコマンドでループを開始してください:

```bash
/ralph-loop "$(cat PROMPT.md)" --max-iterations 30 --completion-promise "EXIT_SIGNAL"
```

---

# Goal

`SPEC.md` (要件) と `CLAUDE.md` (開発指針) を読み、要件を実装してください。
完了条件: `CLAUDE.md` の「完了条件」セクションが全て満たされ、かつ自分が作成した PR が全て merged になった時、最終応答に `<promise>EXIT_SIGNAL</promise>` を出力してループを終了する。

# 状態管理ファイル

- `.ralph/state.md` — 各イテレーションの状態 (active PR、fix_attempts、エスカレーション履歴)。**毎イテレーション更新する**
- `.ralph/fix_plan.md` — タスクバックログ (Phase 単位)。**初回イテレーションで `SPEC.md` / `CLAUDE.md` から派生して埋める**

両ファイルとも commit する (PR 内に含める)。

---

# Per-iteration process

各イテレーションは **必ず Step 0 から順に実行**。

## Step 0: PR triage (CI feedback loop) — 最優先

毎イテレーション最初に必ず実行:

### 0-1. 自分が作成した open PR を取得

```bash
gh pr list --author "@me" --state open --json number,headRefName,mergeable,statusCheckRollup
```

### 0-2. 各 PR の状態判定とアクション

各 PR について以下のルールで分類:

#### A. CI failing → **最優先で修正**

1. ブランチ切替: `git fetch origin && git checkout <branch>`
2. 失敗 job 特定: `gh pr checks <PR>` で `fail` の job を見つける
3. 失敗ログ取得: `gh run view <run-id> --log-failed` (`run-id` は `gh pr checks` 出力から取得、または `gh run list --branch <branch> --limit 1 --json databaseId --jq '.[0].databaseId'`)
4. 原因分析 → コード修正 → ローカルで該当 quality check が green になることを確認
5. `git add -A && git commit -m "fix: ..."` (Conventional Commits)
6. `git push`
7. `.ralph/state.md` の該当 PR の `fix_attempts` をインクリメント
8. **このイテレーションを終了** (Stop フックが次イテレーションを起動して再 CI チェック)

#### B. CI green / mergeable → auto-merge 確実化

```bash
gh pr merge <PR> --auto --squash --delete-branch
```

(冪等。既に設定済の PR でも安全。)

#### C. CI 進行中 (queued / in_progress) → 触らない

次の PR の判定に進む。

### 0-3. エスカレーション判定

`.ralph/state.md` を確認し、**同一 PR の `fix_attempts` が 3 に達した場合**:

1. escalation issue を作成:
   ```bash
   gh issue create --title "Escalation: PR #<N> の CI が 3 回連続で解消できず" --body "..."
   ```
   body には: PR 番号、branch 名、最後の失敗ログ抜粋、試行した修正内容を記載
2. `.ralph/state.md` に `escalated: PR-<N>` を記録
3. 最終応答に `<promise>EXIT_SIGNAL</promise>` を出力してループを終了

### 0-4. Step 0 で何らかのアクション (修正 push、auto-merge 設定、escalation) を行った場合

**Step 1 以降をスキップしてイテレーション終了**。次イテレーションで再度 Step 0 から。

---

## Step 1: タスク選択 (Step 0 で何もしなかった場合のみ)

### 1-1. 状態確認

`.ralph/state.md` を読み、active PR と完了タスクを確認。

### 1-2. fix_plan.md 確認・初期化

`.ralph/fix_plan.md` を読み、pending タスクを確認。

**初回イテレーションで fix_plan.md が空の場合**:
- `SPEC.md` と `CLAUDE.md` の「完了条件」を読む
- Phase 単位 (例: `Phase 1: ユーザー認証`、`Phase 2: DB スキーマ`) でタスクを派生
- 各 Phase に short slug を付ける (例: `user-auth`、`db-schema`)
- `.ralph/fix_plan.md` の `## Pending tasks` に列挙

### 1-3. 次のタスクを 1 件選ぶ

`fix_plan.md` の最上位の pending タスクを選択。

タスクの粒度: **1 PR で diff 200 行以下が目安**。超える Phase はサブ Phase に分割する判断を Claude が行う。

---

## Step 2: ブランチ作成 + 実装

```bash
git fetch origin
git checkout main
git pull --ff-only
git checkout -b claude/phase-{N}-{slug}
```

例: `claude/phase-1-user-auth`

実装は **TDD 推奨**: テストを先に書き、failing を確認してから production code を書く。

production code とテストを **同じコミットに含める** (or 連続コミット)。

---

## Step 3: ローカル品質チェック

<!-- LANG_SPECIFIC_QUALITY_START -->
**派生テンプレートで以下を言語固有コマンドに置き換える**。例:
- TypeScript: `npm run check` (typecheck + lint + format + test)
- Python: `uv run ruff check && uv run mypy && uv run pytest`
- Go: `go test ./... && go vet ./...`
- Rust: `cargo check && cargo test && cargo clippy`

```bash
make check 2>/dev/null || npm run check 2>/dev/null || true
```
<!-- LANG_SPECIFIC_QUALITY_END -->

失敗したら同イテレーション内で修正。green になるまで Step 4 に進まない。

---

## Step 4: コミット + プッシュ + PR 作成

### 4-1. コミット

```bash
git add -A
git commit -m "feat(<scope>): <description>"
```

Conventional Commits 形式: `feat:`, `fix:`, `refactor:`, `test:`, `chore:`, `docs:` 等。

### 4-2. プッシュ

```bash
git push -u origin claude/phase-{N}-{slug}
```

### 4-3. PR 作成

```bash
gh pr create --title "Phase {N}: {phase 名}" --body "..." --base main
```

PR body には: 何を実装したか、関連する SPEC.md セクション、テスト追加内容、関連する完了条件チェック。

### 4-4. **作成直後に auto-merge を有効化**

```bash
gh pr merge <new-PR> --auto --squash --delete-branch
```

CI の `quality` job (および設定されている場合 `e2e`) が green になり次第自動マージされる。CI 失敗の場合は次イテレーションの Step 0 で検知して修正に入る。

---

## Step 5: 状態更新

`.ralph/state.md` を更新:

- `last_iteration` をインクリメント
- 新規 PR を `アクティブ PR` テーブルに追加 (PR 番号、branch、phase 名、`CI status: pending`、`fix_attempts: 0`)
- `完了タスク` セクションに該当 phase を追加 (PR 提出時点で「実装完了」扱い、merged 確認は後続イテレーションの Step 0 で)
- `.ralph/fix_plan.md` の対応タスクに `[x]` を付与

state.md / fix_plan.md の変更は **Step 4 のコミットに含める** (別コミットにしない)。

---

## Step 6: 完了判定

### 6-1. CLAUDE.md の完了条件チェック

`CLAUDE.md` の「完了条件」セクションの全項目を上から確認。

### 6-2. PR 全 merged 確認

```bash
gh pr list --author "@me" --state open --json number
```

空配列であることを確認。

### 6-3. 完了判定

両条件を満たす場合:

- `.ralph/state.md` に `completed_at: <ISO8601>` を記録 (このコミットを最終 PR にまとめる、または直接 main に push せず別 PR で出す)
- 最終応答に `<promise>EXIT_SIGNAL</promise>` を出力してループ終了

そうでなければ通常終了 (Stop フックが次イテレーションを起動)。

---

# 制約 (Constraints)

- **main 直 push 禁止**。常に PR 経由
- 1 phase = 1 PR が原則 (大きい場合はサブ phase に分割)
- diff 200 行を超える PR は再分割を検討
- production code とテストをセットでコミット
- main へのマージは auto-merge + branch protection の `quality` チェック green 必須
- secrets (`CLAUDE_CODE_OAUTH_TOKEN` / `GITHUB_TOKEN` 等) を画面・PR・コミットメッセージ・コードに出力しない
- `.ralph/` 配下と PROMPT.md / CLAUDE.md / SPEC.md は手動編集対象外 (このループの責務外)

# 失敗時 escalation

- **同一 PR の `fix_attempts >= 3`** → Step 0-3 で escalation issue + `<promise>EXIT_SIGNAL</promise>`
- **`max-iterations` 到達** → ralph-loop が自動終了 (state file 削除)
- **致命的なエラー** (リポジトリ破損、認証喪失、SPEC.md / CLAUDE.md 欠落) → 修復試みず最終応答に `<promise>EXIT_SIGNAL</promise>` + 状況を `.ralph/state.md` に記録

# 完了シグナル

正確な書式 (前後の空白は ralph-loop 側で正規化される):

```
<promise>EXIT_SIGNAL</promise>
```

**完了条件を満たしていない状態で出力してはならない**。誤完了は本ループの最大の失敗。
