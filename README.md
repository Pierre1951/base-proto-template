# base-proto-template

言語非依存の最小プロトタイプテンプレートです。Claude Code Action、CI/CD の枠組み、Branch Protection 用の job 名、Issue Template 等、**すべての派生 Template で共通する基盤**を提供します。

## 位置づけ

このテンプレートは 2 つの使い方を想定しています。

### 用途 1: 言語非依存プロジェクトの雛形

シェルスクリプト集、ドキュメントリポジトリ、静的 HTML 実験など、特定言語のビルドを必要としないプロジェクトの出発点として利用できます。

### 用途 2: 新しい派生 Template を作る時の出発点

TypeScript 以外の言語 (Python、Rust、Go 等) でプロトタイプ環境を立ち上げたい時、このテンプレートを `gh repo create --template` でクローンし、言語固有のファイル (devcontainer image、CI スクリプト、依存管理ファイル、サンプルコード) を追加することで新しい派生 Template を作成できます。

## 同梱内容

- `.devcontainer/` — 汎用 Ubuntu ベースの devcontainer 定義 (言語ランタイム未導入)
- `.github/workflows/ci.yml` — `quality` job 名のプレースホルダー CI (常に成功)
- `.github/workflows/claude.yml` — Claude Code Action の最小発火定義
- `.github/ISSUE_TEMPLATE/claude-task.yml` — Claude タスク Issue テンプレート
- `.claude/settings.json` — git/gh/基本コマンドのみの permissions と sandbox
- `CLAUDE.md` — 汎用エージェント指針の骨格
- `LICENSE` — MIT
- `.gitignore` — OS / エディタの artifact のみ

## 派生 Template を作る手順

1. このテンプレートから新リポジトリを生成:
   ```bash
   gh repo create <new-lang-template-name> \
     --template <owner>/base-proto-template \
     --public --clone
   cd <new-lang-template-name>
   ```

2. 言語固有ファイルを追加:
   - `.devcontainer/devcontainer.json` の `image` を言語用に差し替え
   - `.github/workflows/ci.yml` の `quality` job の中身を実際の checks で上書き
   - `.github/workflows/claude.yml` に言語 setup 手順を追加 (例: `setup-node` + `npm ci`)
   - `.claude/settings.json` の `permissions.allow` と `sandbox.network.allowedDomains` に言語固有のコマンドと domain を追加
   - `CLAUDE.md` に言語固有の設計原則・禁止事項・コマンド一覧を追記
   - `.gitignore` に言語固有の artifact を追記
   - 依存管理ファイル (`package.json` / `pyproject.toml` / `Cargo.toml` 等) とサンプルコードを追加

3. コミットしてプッシュ、リポジトリの Settings → Template repository を有効化:
   ```bash
   git add .
   git commit -m "feat: add <language> specific setup"
   git push
   gh repo edit --template
   ```

4. Skill の `templates.json` に新 Template を登録 (詳細はワークフロー構築ガイドの「Template 追加手順」参照)。

## ライセンス

MIT
