#!/bin/sh
# check-suppressions.sh: コメント規約（muse-workspace README「コメント」）の機械検査。
# 指定した差分範囲（または HEAD のツリー全体）の追加行を走査し、lint や型チェックの
# 抑制指定があれば報告する。判定できるのは抑制指定のパターンだけであり、コメント
# 一般の適否は独立レビューの観点が担う（このスクリプトはそちらを代替しない）。
#
# 使い方:
#   sh scripts/check-suppressions.sh [範囲]
#   範囲は git diff の範囲表記（例: origin/main..HEAD）。省略時は HEAD の
#   ツリー全体を走査する。範囲が明示されたのに使えない場合（force push で
#   before が到達不能になった等）は、ツリー走査へ切り替えず、範囲が使えない
#   旨を出力して終了コード 2 で終わる（黙って合格させない）。
# 終了コード: 0 = 違反なし（警告のみの場合を含む）, 1 = 違反あり, 2 = 実行エラー
# 例外の扱い:
#   - prettier-ignore は対象パターンに含めない（規約の例外であるため）
#   - 抑制指定と同じ行に URL（課題や RFC へのリンク）がある場合は、違反ではなく
#     警告として報告する（根拠へのリンクを伴う抑制はレビューで判断する）
#   - Markdown と JSON（文書・データ）と、このスクリプト自体は走査対象から除く

set -u

range="${1:-}"

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "check-suppressions: git リポジトリの中で実行してください" >&2
    exit 2
}
cd "$repo_root" || exit 2

patterns='eslint-disable|tslint:disable|@ts-ignore|@ts-nocheck|@ts-expect-error|type:[[:space:]]*ignore|mypy:[[:space:]]*ignore-errors|noqa|pylint:[[:space:]]*disable|shellcheck[[:space:]]+disable|nolint|@SuppressWarnings|istanbul[[:space:]]+ignore|v8[[:space:]]+ignore|c8[[:space:]]+ignore|pragma:[[:space:]]*no[[:space:]]*cover|@formatter:off'

# 走査対象のパス指定（除外を含む）を位置パラメータに組み立てる
set -- . ':(exclude)*.md' ':(exclude)*.json' ':(exclude)scripts/check-suppressions.sh' ':(exclude)data/evaluator-faults/*'

mode="tree"
if [ -n "$range" ]; then
    if git diff "$range" >/dev/null 2>&1; then
        mode="diff"
    else
        echo "check-suppressions: 指定された範囲が使えません: $range" >&2
        exit 2
    fi
fi

work_file="/tmp/.check-suppressions-added.$$"
trap 'rm -f "$work_file"' EXIT

if [ "$mode" = "diff" ]; then
    # 追加行だけを取り出し、ファイル名と組で作業ファイルへ書く
    git diff --unified=0 --no-color "$range" -- "$@" 2>/dev/null |
    awk '
        /^\+\+\+ b\// { file = substr($0, 7); next }
        /^\+/ && !/^\+\+\+/ { print file "\t" substr($0, 2) }
    ' > "$work_file"
else
    # ツリー走査では、パターンに当たった行だけが初めから入っている
    git grep -n -I -E "$patterns" HEAD -- "$@" 2>/dev/null |
    sed -E 's/^HEAD:([^:]*):[0-9]+:/\1\t/' > "$work_file"
fi

tab=$(printf '\t')
violations=0
warnings=0

while IFS="$tab" read -r file content; do
    [ -n "${content:-}" ] || continue
    if [ "$mode" != "tree" ]; then
        printf '%s' "$content" | grep -qE "$patterns" || continue
    fi
    if printf '%s' "$content" | grep -qE 'https?://'; then
        echo "警告（リンク付き抑制、レビューで判断）: $file: $content" >&2
        warnings=$((warnings + 1))
    else
        echo "違反（抑制指定）: $file: $content" >&2
        violations=$((violations + 1))
    fi
done < "$work_file"

if [ "$violations" -gt 0 ]; then
    echo "check-suppressions: 抑制指定が ${violations} 件見つかりました（警告 ${warnings} 件）。規約の例外に当たるかは muse-workspace README「コメント」を確認してください" >&2
    exit 1
fi

if [ "$warnings" -gt 0 ]; then
    echo "check-suppressions: リンク付き抑制が ${warnings} 件あります（違反ではありません。レビューで根拠を確認してください）" >&2
fi

exit 0
