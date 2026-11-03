# public-form-verification

公開形（形態P）の運用検証専用リポジトリ。

## 目的

リポジトリを公開するときに有効化する部品一式（ブランチ保護、限定クラスの auto-merge、CodeQL、secret scanning と push protection、PR 経由の統合の流れ）が、公開リポジトリで実際に有効化でき、期待どおりに動くことを実測で確かめるための検証用リポジトリである。検証対象の設計の正は `ksk-muse-bot/muse-workspace` 側の記録（リポジトリ公開と PR 運用の設計）にあり、このリポジトリ自体は製品でも雛形でもない。

背景: muse-template の公開は 2026-11-03 に見送られた（履歴の著者メタデータに、接尾辞を外すと個人のメールアドレスが推測できる形式が含まれていたため）。形態Pの検証は、著者メタデータを最初から識別不能な形に揃えたこのリポジトリで代替する。

## 検証する項目

- secret scanning と push protection を有効化し、状態を読み戻せること
- ブランチ保護（必須チェック checks／environment／taint、必須承認数 0）を適用できること
- allow_auto_merge を有効化し、PR で auto-merge が実際に働くこと
- CodeQL を有効化し、解析が実行されること
- PR 経由の流れ（文脈のないレビュー記録 → 必須チェック通過 → マージ）が通しで回ること

## 構成

- `.github/workflows/checks.yml`: 雛形（muse-template v2.4.0）相当の検査ワークフロー
- `verification_sample.py`: CodeQL と Pysa の解析対象にする小さな Python ファイル
- `docs/project-record.md`: このプロジェクトの正本記録（検証結果もここに残す）

検証の進捗と結果は `docs/project-record.md` に記録する。このリポジトリには、個人を特定できる情報を一切置かない。

## PR 経由の統合の実走

2026-11-03、形態Pの検証の一環としてこの節を PR 経由で追加した。文脈のないレビュー記録、必須チェック（checks／environment／taint）の通過、auto-merge の実挙動を通しで確認するための変更である。結果は `docs/project-record.md` に記録する。

なお、この節への追記は2回目の PR で行い、auto-merge をチェック完了前に有効化して GitHub が自動でマージする経路そのものを実測した（2026-11-03）。
