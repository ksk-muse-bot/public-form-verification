#!/bin/sh
# Git フックの導入スクリプト
# scripts/hooks/ のフックを .git/hooks/ へコピーし、実行可能にする。
# 使い方: リポジトリのルートで `sh scripts/install-hooks.sh`
set -eu

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

for hook in pre-commit commit-msg pre-push; do
    cp "scripts/hooks/$hook" ".git/hooks/$hook"
    chmod +x ".git/hooks/$hook"
    echo "導入しました: .git/hooks/$hook"
done

echo "完了。コミット時（メッセージ形式と変更内容）とプッシュ時に検査が走ります。"
