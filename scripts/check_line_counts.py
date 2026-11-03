#!/usr/bin/env python3
"""ファイル行数の決定的チェック（読み手負荷の規約の機械検査）。

背景: 手書きファイルは作成時点では行数を守っても、修正の繰り返しで
際限なく伸び、人間にも AI にも読めなくなる。本チェックは次の3層で
それを止める。

1. 目安（soft_target）: 超えたら警告を出す（失敗にはしない）。
   分割の検討を始める水準。
2. 上限（hard_cap）: ベースラインに無いファイルが超えたら失敗。
3. ラチェット: 上限を既に超えている既存ファイルは、ベースライン
   （scripts/line-count-baseline.json）に現状の行数を記録し、
   その値から1行でも増えたら失敗する。減らす方向は常に可。

対象はコードと手書き文書のみ。データ実体（JSON 等）と生成物は
対象にしない（生成物はベースラインの excluded に明示する）。
数値の根拠と出所は muse-workspace のプロジェクト記録
（2026-11-03 の基盤規約棚卸し）に記録する。

使い方:
  python3 scripts/check_line_counts.py                  検査する
  python3 scripts/check_line_counts.py --write-baseline ベースラインを現状で再生成する

終了コード: 0 = 合格（警告はありうる）。1 = 違反あり。
2 = ベースラインが読めない等、検査できない状態（黙って通さない）。
標準ライブラリのみ・システム Python で動かす。
"""
import json
import sys
from pathlib import Path

CODE_EXTS = {".py", ".js", ".ts", ".jsx", ".tsx", ".mjs", ".cjs", ".sh", ".go", ".rs", ".pysa", ".tla", ".mmd"}
DOC_EXTS = {".md"}
EXCLUDED_DIRS = {".git", "node_modules", ".venv", "venv", "__pycache__", ".scratch"}
DEFAULT_BASELINE = Path(__file__).resolve().parent / "line-count-baseline.json"


def classify(path):
    ext = path.suffix.lower()
    if ext in CODE_EXTS:
        return "code"
    if ext in DOC_EXTS:
        return "docs"
    return None


def count_lines(path):
    text = path.read_text(encoding="utf-8")
    if not text:
        return 0
    return text.count("\n") + (0 if text.endswith("\n") else 1)


def iter_targets(root, excluded):
    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(root).as_posix()
        if any(part in EXCLUDED_DIRS for part in Path(rel).parts):
            continue
        if rel in excluded:
            continue
        if classify(path) is None:
            continue
        yield rel, path


def load_baseline(path):
    data = json.loads(path.read_text(encoding="utf-8"))
    for key in ("soft_target", "hard_cap", "over_cap", "excluded"):
        if key not in data:
            raise ValueError(f"ベースラインに必須キー {key} がありません")
    return data


def check(root, baseline):
    excluded = set(baseline["excluded"])
    over_cap = baseline["over_cap"]
    warnings = []
    violations = []
    for rel, path in iter_targets(root, excluded):
        kind = classify(path)
        try:
            lines = count_lines(path)
        except (UnicodeDecodeError, OSError) as exc:
            violations.append(f"{rel}: 行数を数えられません（{exc}）")
            continue
        if rel in over_cap:
            if lines > over_cap[rel]:
                violations.append(
                    f"{rel}: {lines} 行。ラチェット上限 {over_cap[rel]} 行を超えました"
                    "（上限超の既存ファイルは増やせません。分割してください）")
            continue
        hard = baseline["hard_cap"][kind]
        soft = baseline["soft_target"][kind]
        if lines > hard:
            violations.append(
                f"{rel}: {lines} 行。上限 {hard} 行（{kind}）を超えました"
                "（分割するか、やむを得ない場合はベースラインへ理由つきで登録してください）")
        elif lines > soft:
            warnings.append(f"{rel}: {lines} 行。目安 {soft} 行（{kind}）を超えています（分割を検討）")
    return warnings, violations


def write_baseline(root, baseline_path):
    existing = {}
    if baseline_path.exists():
        existing = load_baseline(baseline_path)
    baseline = {
        "version": 1,
        "soft_target": existing.get("soft_target", {"code": 300, "docs": 300}),
        "hard_cap": existing.get("hard_cap", {"code": 600, "docs": 600}),
        "over_cap": {},
        "excluded": existing.get("excluded", []),
    }
    excluded = set(baseline["excluded"])
    for rel, path in iter_targets(root, excluded):
        kind = classify(path)
        lines = count_lines(path)
        if lines > baseline["hard_cap"][kind]:
            baseline["over_cap"][rel] = lines
    baseline["over_cap"] = dict(sorted(baseline["over_cap"].items()))
    baseline_path.write_text(
        json.dumps(baseline, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return baseline


def main(argv):
    root = Path(__file__).resolve().parent.parent
    baseline_path = DEFAULT_BASELINE
    if "--root" in argv:
        root = Path(argv[argv.index("--root") + 1]).resolve()
    if "--baseline" in argv:
        baseline_path = Path(argv[argv.index("--baseline") + 1])
    if "--write-baseline" in argv:
        baseline = write_baseline(root, baseline_path)
        print(f"ベースラインを書きました: {baseline_path}"
              f"（上限超の登録 {len(baseline['over_cap'])} 件）")
        return 0
    if not baseline_path.exists():
        print(f"ベースラインがありません: {baseline_path}（--write-baseline で作成してください）")
        return 2
    try:
        baseline = load_baseline(baseline_path)
    except (ValueError, json.JSONDecodeError) as exc:
        print(f"ベースラインを読めません: {exc}")
        return 2
    warnings, violations = check(root, baseline)
    for w in warnings:
        print(f"警告: {w}")
    for v in violations:
        print(f"違反: {v}")
    if violations:
        print(f"行数チェック: 違反 {len(violations)} 件、警告 {len(warnings)} 件")
        return 1
    print(f"行数チェック: 合格（警告 {len(warnings)} 件）")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
