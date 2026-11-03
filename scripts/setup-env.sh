#!/usr/bin/env bash
# 環境セットアップの入口。リポジトリにある契約ファイルを見て、
# 該当するエコシステムの環境を用意する（単一ファイルで完結させる）。
set -euo pipefail
cd "$(dirname "$0")/.."
found=0

if [ -f .python-version ]; then
  found=1
  if [ ! -d .venv ]; then
    python3 -m venv .venv
    echo ".venv を作成しました"
  fi
  if [ -f requirements.txt ] && grep -qvE '^\s*(#|$)' requirements.txt; then
    .venv/bin/python -m pip install -r requirements.txt
  fi
  .venv/bin/python --version
fi

if [ -f package.json ]; then
  found=1
  if [ -f .nvmrc ] && [ -s "$HOME/.nvm/nvm.sh" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.nvm/nvm.sh"
    nvm use
  fi
  node --version
  if [ -f package-lock.json ]; then
    npm ci
  elif [ -f pnpm-lock.yaml ]; then
    corepack enable pnpm
    pnpm install --frozen-lockfile
  elif [ -f yarn.lock ]; then
    yarn install --frozen-lockfile
  else
    echo "lockfile がありません。依存の固定が前提です" >&2
    exit 1
  fi
fi

if [ -f go.mod ]; then
  # Go はモジュール単位で依存解決が道具に組み込まれているため、契約は go.mod 自体。
  found=1
  go version
fi

if [ -f Cargo.toml ]; then
  # Rust も Cargo がプロジェクト単位で解決する。版の固定は rust-toolchain.toml で行う。
  found=1
  cargo --version
fi

if [ "$found" -eq 0 ]; then
  echo "環境の契約ファイルが見つかりません（.python-version / package.json / go.mod / Cargo.toml）" >&2
  exit 1
fi
