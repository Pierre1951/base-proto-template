FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# 開発汎用ツール
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git curl jq ripgrep fd-find tmux htop \
    && rm -rf /var/lib/apt/lists/*

# Ubuntu の fd-find は実行ファイル名が fdfind なので fd への symlink を作成
RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd

# Node.js 20 + Claude Code CLI
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g @anthropic-ai/claude-code \
    && npm cache clean --force

# vscode ユーザーは base イメージに既存 (uid 1000)
USER vscode
WORKDIR /workspace
