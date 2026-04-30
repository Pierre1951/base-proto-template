# base-proto-template

claude-dev VPS 自動開発ワークフロー用の **メタテンプレート** + **最小プロジェクトテンプレート**。

## 役割

このリポジトリは 2 つの使い方を想定:

### 1. メタテンプレート (派生テンプレートを作る土台)

言語固有のテンプレート (例: `ts-game-proto-template`、`python-cli-proto-template`、`go-api-proto-template`) を作る出発点。TypeScript / Python / Go / Rust などへの分岐元として利用。

### 2. 最小プロジェクトテンプレート (言語非依存プロジェクト用)

シェルスクリプト集・ドキュメントリポジトリ・静的 HTML 実験など、特定言語のビルドを必要としないプロジェクトの直接利用。

---

## 含まれるもの

| ファイル/ディレクトリ | 役割 |
|---|---|
| `.devcontainer/devcontainer.json` | dockerComposeFile 参照 (compose ベース) |
| `docker-compose.yml` | dev サービス定義、`/home/ubuntu/.claude` を `/home/vscode/.claude` に volume mount (claude-config の dotfiles 等価運用) |
| `Dockerfile` | Ubuntu 24.04 + Node 20 + Claude Code CLI + 開発汎用ツール |
| `.github/workflows/ci.yml` | `quality` job placeholder (派生テンプレで上書き) |
| `.github/workflows/claude.yml` | @claude mention で Runner 上 Claude Code 起動 (VPS 独立、PR/Issue 単発処理用) |
| `.github/ISSUE_TEMPLATE/claude-task.yml` | Claude タスク Issue テンプレート |
| `.claude/settings.json` | プロジェクトレベル permissions / sandbox 設定 |
| **`PROMPT.md`** | **ralph-loop 自律開発用プロンプト (本リポジトリの核心)** |
| **`.ralph/state.md`** | **ralph-loop 状態管理 scaffold (active PR / fix_attempts / 完了タスク)** |
| **`.ralph/fix_plan.md`** | **タスクバックログ scaffold (Phase 単位)** |
| `CLAUDE.md` | プロジェクト指針 (派生 / 最終プロジェクトで上書き) |
| `LICENSE` | MIT |
| `.gitignore` | OS / エディタ artifact + ralph-loop 個人作業ファイル除外 |

---

## ワークフロー全体図

```mermaid
flowchart LR
  subgraph Local[ローカル]
    SPEC[spec.md]
  end
  subgraph GH[GitHub]
    BASE[base-proto-template<br/>本リポジトリ]
    DERIV[派生テンプレ<br/>ts-game-proto-template 等]
    PROJ[Pierre1951/myapp<br/>新規プロジェクト]
    CLAUDE_ACTION[claude.yml<br/>Runner 上 Claude]
  end
  subgraph VPS[Vultr VPS]
    DC[devcontainer<br/>+ ~/.claude mount]
    LOOP[ralph-loop<br/>自律開発]
  end

  BASE -.->|Template| DERIV
  SPEC -->|/init-devenv| INIT[init-devenv skill]
  INIT -->|gh repo create --template| DERIV
  DERIV -.->|Template| PROJ
  INIT -->|VPS provisioning + bootstrap| VPS
  PROJ -->|gh repo clone on VPS| DC
  DC -->|claude<br/>+ /ralph-loop| LOOP
  LOOP -->|gh pr create<br/>+ auto-merge| PROJ
  PROJ -->|@claude mention<br/>(別経路)| CLAUDE_ACTION

  style BASE fill:#fef3c7
  style LOOP fill:#d1fae5
  style CLAUDE_ACTION fill:#dbeafe
```

---

## 派生テンプレートの作り方

1. このリポジトリを GitHub Template として新規 repo 作成:
   ```bash
   gh repo create <owner>/<new-lang-template-name> \
     --template <owner>/base-proto-template \
     --public --clone
   cd <new-lang-template-name>
   ```

2. 言語固有ファイルを追加・編集:
   - `Dockerfile` に言語ランタイムを追加 (例: TypeScript なら Playwright base へ変更、Python なら `apt install python3-pip`)
   - `.github/workflows/ci.yml` の `quality` job を実際の checks で上書き (lint / typecheck / format / test)
   - `.github/workflows/claude.yml` に言語 setup を追加 (`setup-node` / `setup-python` 等)
   - `.claude/settings.json` の `permissions.allow` に言語コマンドを追加 (`Bash(npm *)` / `Bash(pip *)` 等)
   - `CLAUDE.md` の `## コーディング規約` `## よく使うコマンド` セクションを言語固有内容で埋める
   - **`PROMPT.md` の `<!-- LANG_SPECIFIC_QUALITY_START -->` マーカー間を言語固有コマンドに置換** (例: `npm run check`)
   - 依存管理ファイル (`package.json` / `pyproject.toml` / `Cargo.toml` 等) とサンプルコードを追加
   - `.gitignore` に言語固有の artifact (`node_modules/` / `__pycache__/` 等) を追記

3. コミット → push → Template repository 有効化:
   ```bash
   git add -A
   git commit -m "feat: add <language> specific setup"
   git push
   gh repo edit --template
   ```

4. `init-devenv` スキルの `templates.json` に新テンプレ repo を登録。

---

## 最終プロジェクト作成時の流れ (init-devenv 経由)

1. ローカルで仕様 md を作成
2. Claude Code で `/init-devenv path/to/spec.md` 実行
3. 適合する派生テンプレ (本リポジトリ含む) と Workload tier を選択
4. `init-devenv` がリポジトリ生成 + Vultr VPS provisioning + devcontainer up まで自動化
5. ユーザーが VPS に SSH ログイン:
   ```bash
   ssh claude-dev-<project>
   cd ~/<project>
   devcontainer exec --workspace-folder . bash
   claude
   ```
6. Claude Code 内で:
   ```
   /ralph-loop "$(cat PROMPT.md)" --max-iterations 30 --completion-promise "EXIT_SIGNAL"
   ```
7. ループが CI と PR を介して自律開発 → 完了マージ → `<promise>EXIT_SIGNAL</promise>` で終了
8. `vultr-cli instance delete <id>` で VPS 削除 (プロジェクト状態は GitHub に永続化)

---

## ralph-loop と claude.yml の使い分け

| ケース | 使うもの |
|---|---|
| プロジェクト初期実装の自動完遂 | **ralph-loop** (VPS 上で自律ループ) |
| 既存 PR への部分修正・review コメント対応 | **claude.yml** (PR コメントに `@claude ...` mention) |
| 大規模 refactor / 設計変更 | **ralph-loop** |
| 単発の質問・分析・小修正 | **claude.yml** |
| CI 失敗時の修正 | **ralph-loop** が Step 0 で自動検知 → 修正 (人手介入不要) |

ralph-loop は VPS 上で実行 (永続的・大規模)、claude.yml は GitHub Actions Runner で実行 (ephemeral・単発)。両者は独立で同時並行可能。

---

## CI フィードバックループ (核心)

ralph-loop は毎イテレーションの **Step 0** で自分が作成した PR の CI 状態を確認し、failing なら修正に入ります。これにより:

- CI 失敗 = ループ停止 ではない
- 失敗ログを `gh run view --log-failed` で読み、原因を特定して修正 push
- 同一 PR で 3 回連続 fix 失敗 → escalation issue 自動作成 + ループ終了

詳細は `PROMPT.md` 参照。

---

## ライセンス

MIT
