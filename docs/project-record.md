# プロジェクト記録: public-form-verification

- 作成日: 2026-11-03
- 最終更新: 2026-11-04（可視性の往復切り替え検証の完了: 破壊されるのはブランチ保護のみで、再適用済み）
- セキュリティレベル: 標準
  - 判定: 個人データ・資格情報・機微な領域のデータのいずれも扱わない（すべて「いいえ」）ため標準。なお標準レベルの要件には「非公開」が含まれるが、本プロジェクトは可視性そのものが検証対象であり、公開はユーザー決定（2026-11-03、このリポジトリに限る）による例外である。機微さをゼロに保つ条件として、個人を特定できる情報をファイル・履歴・PR のいずれにも置かない。ただしマージコミットの author については、GitHub の仕様によりこの条件を完全には満たせないことが実測で判明した（課題・問題の1件目）。
- 雛形バージョン: v2.4.0（生成ではなくファイル複写で採用した。理由は決定履歴の1件目）
- プロファイル: 標準（コード+CI）／形態: P（公開）— 形態Pの適用そのものが本プロジェクトの検証対象

## 目的

公開形（形態P）の部品一式（ブランチ保護、限定クラスの auto-merge、CodeQL、secret scanning／push protection、PR 経由の統合の流れ）を、公開リポジトリへ実適用して検証する。muse-template の公開見送り（2026-11-03）により、形態Pの検証はこちらで代替する。

## 範囲

### 対象

- 形態Pの各部品の有効化可否と実挙動の実測
- PR 経由の統合の流れの通し実走（文脈のないレビュー記録 → 必須チェック → auto-merge または統合役の有効化によるマージ）
- 検証結果の記録（本記録と、ai-base ゴールの build-state.json の該当項目）

### 対象外

- muse-template 自体の公開（見送りが決定済み。再開条件は別途の判断）
- 検証完了後のこのリポジトリの扱いの決定（残す／アーカイブ／削除はユーザーの判断事項）
- 他リポジトリへの形態Pの適用（検証結果を受けた個別判断）

## 構成

- `README.md`: 検証の目的と項目
- `AGENTS.md`: 常駐命令
- `docs/project-record.md`: 本記録
- `.github/workflows/checks.yml`: 雛形相当の検査（ジョブ checks／environment／taint）
- `.github/dependabot.yml`: github-actions と pip の更新
- `verification_sample.py`: CodeQL／Pysa の解析対象
- `scripts/`: 雛形の土台スクリプト（抑制スキャン、行数チェック）。フック類と環境セットアップは入れていない（決定履歴の5件目）
- `.pyre_configuration`、`.pysa-models/`: taint ジョブ（Pysa）の設定

配置ルール:

- ソース: リポジトリ直下（検証用の最小構成）
- ドキュメント: `docs/`
- 生成物: 置かない

## 運用ルール

- GitHub への読み書きは gh_api.py（custom.github-ksk-bot コネクタ）経由のみ。コミットには `Executor:` trailer が必須
- コミットの author／committer は `ksk-muse-bot <348520711+ksk-muse-bot@users.noreply.github.com>` で明示指定する（決定履歴の2件目）。ただしマージコミットは GitHub が author を決めるため対象外になる（課題・問題の1件目）
- 個人を特定できる情報を、ファイル・コミットメッセージ・PR のいずれにも入れない

## 決定履歴

| 日付 | 決定 | 根拠 | 置き換えた決定 |
| --- | --- | --- | --- |
| 2026-11-03 | 雛形からの生成ではなく、空のリポジトリへ雛形 v2.4.0 の土台ファイルを複写して開始する | 雛形生成の初回コミットは著者が bot 登録メールの plus-alias 形式になることが、既存リポジトリ（grok-bot-research の Initial commit）の実物で確認されている。公開時に接尾辞を外した個人のメールアドレスが推測可能になるため、本プロジェクトでは公開前に履歴へ識別可能な著者を一切入れない経路が要る。生成では初回コミットの著者を制御できない | なし |
| 2026-11-03 | コミットの author／committer は noreply 形式（ID 付き）で明示指定する | gh_api.py 経由のコミットは、著者を指定しないとアカウント登録メール（plus-alias 形式）が既定になることを既存リポジトリの履歴で実測した。Git Data API は著者の明示指定を受け付ける | なし |
| 2026-11-03 | release ワークフローは入れない | main へ直接 push する release の流れは、PR を必須とするブランチ保護と競合する。検証範囲を形態Pの部品に絞るため除外した（release と保護の共存の検証は、必要になった時点で別途扱う） | なし |
| 2026-11-03 | 公開はこのリポジトリに限る（ユーザー決定済みの範囲） | muse-template の公開見送りに伴う代替検証であり、他のリポジトリの公開可否は個別判断のまま | なし |
| 2026-11-03 | フック類（scripts/hooks/、install-hooks.sh）と scripts/setup-env.sh は入れない | 雛形の既存分に含まれる shellcheck 抑制指定2件（setup-env.sh の SC1091、hooks/pre-commit の SC2086）は、雛形側では既存分として管理されているが、このリポジトリの初回差分ではコメント規約スキャン（check-suppressions.sh）が新規の違反として検出し、checks が failure になった（run 41612663705 で実測）。検証に不要なファイルであり、新規リポジトリの履歴へ抑制指定を持ち込まないため除外した | なし |
| 2026-11-03 | checks.yml の shellcheck ステップは、対象を実在するファイルだけに限定する形へ読み替える | フック類を入れない構成では雛形の glob（scripts/hooks/*）が展開されず、shellcheck が実在しないパスを開いて失敗した（run 41612893192 で実測）。雛形はフック常在が前提のため、この構成差異への読み替えとして記録する | なし |
| 2026-11-03 | CodeQL はファイル方式ではなく default setup で有効化する | API で state=configured の設定と初回解析の開始まで一括で行え、実測で python／actions 両言語の解析が success したため。ファイル方式との併用はできないため、方式は default setup に一本化する | なし |
| 2026-11-03 | ブランチ保護の required_status_checks.strict（マージ前のブランチ最新化）は参照ペイロードどおり true で適用する | 手順書が「設計に明記のない選択であり、適用時に判断する」と申し送っていた点。本検証の PR は main が動かない単独 PR のため実害がなく、最新状態で checks を通過している保証を取る側に倒した | なし |

## 実装状況

### 実装済み

- 土台ファイル一式（雛形 v2.4.0 の複写＋Python バンドルの契約ファイル）
- README、AGENTS.md、本記録、解析対象の Python ファイル
- 公開への切り替え（ブラウザ経路で実施し、API で private=false を読み戻し済み）
- 形態Pの実適用: secret scanning／push protection、ブランチ保護、allow_auto_merge、CodeQL（default setup）
- PR 経由の実走2件: PR #1（統合役によるマージ）、PR #2（auto-merge による自動マージ）

### 未実装

- なし（検証自体は完了。残るのは検証完了後のこのリポジトリの扱いについてのユーザー判断のみ）

## 検証結果（2026-11-03 実測）

| 部品 | 有効化できたか | 期待どおり動いたか | 実測の要点 |
| --- | --- | --- | --- |
| secret scanning | できた（PATCH 200、独立した GET で enabled を読み戻し） | 状態としては期待どおり。アラートは0件 | public 化の直後は disabled 表示だったため、明示設定して読み戻した |
| push protection | できた（同上） | **未実測**（右記の理由） | 秘密らしい文字列の push が GitHub 側で拒否される挙動は、gh_api.py 自身のガードが高信頼パターンを先に拒否するため、正規の経路では GitHub 側の拒否まで到達できず実測していない |
| ブランチ保護 | できた（PUT 200、独立した GET で全項目を読み戻し） | 動いた | 必須チェック checks／environment／taint、strict=true、必須承認数0、enforce_admins=true、force push・削除は不可。PR #1・#2 ともチェック完了前は mergeable_state=blocked で、通過後にのみマージできた。enforce_admins の下で、管理者である bot 自身のマージもチェック待ちになった |
| allow_auto_merge | できた（PATCH 200、get-repo で true を読み戻し） | 動いた（PR #2 で実測） | 下記の auto-merge 行を参照 |
| auto-merge の実挙動 | GraphQL はヘルパーのガードを通った（POST /graphql が拒否されず GitHub へ到達） | 動いた | PR #2: チェック進行中に有効化（2026-11-03T09:53:04Z）→ 全チェック通過後に GitHub が自動マージ（09:53:49Z）。一方、チェック完了済みで clean 状態の PR #1 へ有効化しようとすると GitHub が "Pull request is in clean status" と拒否した（auto-merge は未完了の必須チェックがある状態でのみ有効化できる）。有効化時に指定した commitHeadline／commitBody（Executor trailer を含む）はマージコミットへそのまま反映された |
| CodeQL | できた（default setup、PATCH 202） | 動いた | GET で state=configured、languages=[actions, python]、updated_at を読み戻し。初回解析 run 41613963669 が success で、python／actions 両言語の解析結果（各0件）が登録された。以後も PR・push ごとに実行され、全て success |
| PR 経由の統合の流れ | — | 通しで回った | PR #1: 文脈のないレビュー担当の判定「統合可」を PR コメント（#issuecomment-6600456065）として記録 → 必須チェック全件 success → 統合役が REST でマージ（マージコミット 4e933f80）。PR #2: auto-merge 経路で自動マージ（マージコミット 7909c7d5）。両マージ後の main の checks も全件 success |

### 可視性の往復切り替え検証（2026-11-04 実測）

切り替え前の状態は main 先端 7b9efc1c（.python-version を 3.12.16 へ更新した PR #4 のマージ後）で、設定スナップショットは進捗の準備の行のとおり取得済み。可視性の切り替え自体は gh_api.py のガードが拒否する設計のため、いずれも bot アカウントのブラウザ経路で実施した。

- 往路: Public → Private をブラウザ経路で実施（ランタイム実測 13:09〜13:10 JST。sudo 再認証は保存済みパスワードで実施）。Settings の「This repository is currently private.」表示と Private バッジを確認した。
- private の間の実測: リポジトリの GET で private=true。保持されていた項目は allow_auto_merge=true、delete_branch_on_merge=false（不変）、自動セキュリティ修正 enabled=true／paused=false。リポジトリ GET の security_and_analysis は null で読み取り不可だった。執行できない項目は、ブランチ保護の GET が 403（「Upgrade to GitHub Pro or make this repository public to enable this feature.」）、CodeQL default setup の GET が 403（「Code scanning is not enabled for this repository.」）。
- 復路: Private → Public をブラウザ経路で実施（ランタイム実測 13:11〜13:12 JST。今回は再認証なし）。Settings の「This repository is currently public.」表示と Public バッジを確認した。
- 復帰後の実測: private=false。security_and_analysis は切り替え前と全項目一致（secret_scanning 有効、push protection 有効、dependabot_security_updates 有効、non_provider_patterns 無効、validity_checks 無効）で、自動で復帰していた。CodeQL default setup は state=configured、languages=[actions, python]、query_suite=default で、updated_at は切り替え前の 2026-11-03T09:49:23Z のままだった。つまり設定自体は保持されており、private の間だけ無効に見えた。脆弱性アラート有効（GET で 204）と、自動セキュリティ修正 enabled=true／paused=false も切り替え前と一致した。
- 唯一の非復帰項目はブランチ保護である。GET が 404「Branch not protected」となり、private 化によってルール自体が削除されていた。切り替え前のスナップショット値で再適用し（PUT 200）、再読み取りで全15項目（required_status_checks.strict=true、contexts=[checks, environment, taint]、必須承認数0、dismiss_stale_reviews=false、require_code_owner_reviews=false、require_last_push_approval=false、required_signatures=false、enforce_admins=true、required_linear_history=false、allow_force_pushes=false、allow_deletions=false、block_creations=false、required_conversation_resolution=true、lock_branch=false、allow_fork_syncing=false、restrictions なし）が切り替え前と一致することを確認した。
- 結論: 可視性の切り替えで破壊されるのはブランチ保護のみである。他の設定は保持される（ただし private の間は読み取り・執行ができないものがある）。このため「切り替え＋直後の実測照合＋ブランチ保護の再適用」を必須工程とする両方向の配線（muse-workspace の次のアクションと週次監査の方法文書への追記は実施済み）が正しい担保である。

## 進捗

- 2026-11-03: リポジトリを作成し、土台を初回コミットとして投入した。著者メタデータが noreply 形式であることを実物で確認済み。
- 2026-11-03: 初回の checks でコメント規約スキャンが雛形既存分の抑制指定2件を検出して failure になったため、フック類と setup-env.sh を除外した（決定履歴の5件目）。あわせて、混入した `__pycache__` の .pyc 2件も除去した。
- 2026-11-03: 先端コミット f84e69a9 の checks run 41613107921 が success（ジョブ checks／environment／taint の全て success）。全5コミットの author／committer が noreply 形式のみであることを履歴全体で照合済み。
- 2026-11-03: 可視性の変更を gh_api.py 経由で試行し、ガードが終了コード3で拒否した（リクエストは送信されていない）。公開への切り替えは bot アカウントのブラウザ経路での操作待ち。
- 2026-11-03: 公開への切り替えがブラウザ経路で完了し、gh_api.py の get-repo で private=false／visibility=public を読み戻した。
- 2026-11-03: 形態Pの実適用を完了した（secret scanning／push protection の有効化、allow_auto_merge=true、ブランチ保護の適用、CodeQL default setup の有効化）。いずれも独立した GET で読み戻して確認済み。詳細は「検証結果」の節。
- 2026-11-03: PR #1 で PR 経由の統合を通しで実走した。文脈のないレビュー担当の判定「統合可」の記録を PR コメントとして残し、必須チェック全件 success を確認して統合役がマージした（マージコミット 4e933f80eb932042301829d031ee3bf63df8b743）。
- 2026-11-03: PR #2 で auto-merge の経路を実走した。チェック進行中に auto-merge を有効化し、全チェック通過後に GitHub が自動でマージした（マージコミット 7909c7d5e093）。auto-merge 有効化時の commitBody に含めた Executor trailer がマージコミットへ反映されることも確認した。
- 2026-11-03: 検証結果を本記録へ集約した（この更新自体も、ブランチ保護の下で PR 経由で統合した）。
- 2026-11-04: 可視性の往復切り替え検証（public→private→public）の準備として、切り替え前の設定スナップショットを API で取得した（可視性 public、allow_auto_merge=true、secret scanning／push protection はいずれも enabled、脆弱性アラート有効・自動セキュリティ修正は enabled、ブランチ保護は必須チェック checks／environment／taint・strict=true・必須承認数0・enforce_admins=true・会話の解決必須、CodeQL default setup は state=configured で対象は actions と python）。あわせて muse-workspace の次のアクションの発動条件（同リポジトリへ次にプッシュする時点）により、.python-version を 3.12.3 から 3.12.16 へ更新した（本 PR）。
- 2026-11-04: 可視性の往復切り替え検証（public→private→public）を実施し、完了した。往路はブラウザ経路で 13:09〜13:10 JST（sudo 再認証は保存済みパスワード）、復路は 13:11〜13:12 JST（再認証なし）。private の間の実測と復帰後の実測対照の詳細は「検証結果」の往復切り替え検証の小節が正。結論は、破壊されるのはブランチ保護のみであり、切り替え前のスナップショット値で再適用して全15項目の一致を確認済みであること、他の設定は保持または自動復帰したこと。

## 課題・問題

- **マージコミットの author に bot アカウントの登録メール（plus-alias 形式）が入る**（2026-11-03 実測、PR #1・#2 の両マージコミット）。GitHub のマージ経路（REST のマージ、auto-merge のいずれも）は author を API から指定できず、GitHub がマージ実行者の登録メールで author を決めるためである。通常コミットは noreply 形式で揃えられるが、マージコミットだけは揃えられない。committer は `GitHub <noreply@github.com>` になる。恒久対策（bot アカウントの登録メール自体の変更等）はアカウント運用の判断が要るため、未決として残す。配線先: repo-doc:public-form-verification/docs/project-record.md（本行）と、ai-base ゴールの build-state.json の該当項目。
- 検証用ブランチ2件（`verify/pr-e2e-2026-11-03`、`verify/auto-merge-2026-11-03`）が残っている。ref の削除は gh_api.py のガードが拒否する設計のため、削除にはブラウザ経路等の別手段が要る。残置自体は無害であり、このリポジトリの扱いの判断とあわせて扱う。
- push protection の実挙動（秘密らしい文字列の push の拒否）は未実測である（検証結果の節に理由を記載）。
- 可視性の変更（private → public）は gh_api.py のガードが拒否する設計のため、ヘルパー経由では実施できない。bot アカウントのブラウザ経路での操作が要る。**（2026-11-03、ブラウザ経路で切り替え済みのため解消）**
- **private 化でブランチ保護のルール自体が削除される**（2026-11-04 実測。詳細は「検証結果」の往復切り替え検証の小節）。public へ戻しても自動では復帰しないため、可視性を切り替える作業では切り替え前のスナップショット取得、直後の実測照合、ブランチ保護の再適用を必須工程とする。担保は muse-workspace の次のアクション「形態P設定と可視性の連動（両方向）」と、週次監査の方法文書の両方向照合の手順である。配線先: repo-doc:public-form-verification/docs/project-record.md（本行）

## 次のアクション

- [x] 公開への切り替え（ブラウザ経路）後に、形態Pを実適用し各部品を実測する（2026-11-03 完了）
- [x] PR 経由の実走を行い、レビュー記録・必須チェック・auto-merge の実挙動を記録する（2026-11-03 完了。PR #1・#2）
- [x] 可視性の往復切り替え検証（public→private→public）を行い、破壊・保持される項目を実測して記録する（2026-11-04 完了。ブランチ保護のみが破壊され、スナップショット値で再適用済み。他の設定は保持・自動復帰）
- [ ] 検証完了後のこのリポジトリの扱い（残す／アーカイブ／削除）をユーザーが判断する。配線先: repo-doc:public-form-verification/docs/project-record.md（本行）。あわせて ai-base ゴールの build-state.json の該当項目にも同じ判断待ちを記録する
- [ ] マージコミットの author が登録メール（plus-alias 形式）になる問題への恒久対策を判断する（アカウントの登録メール変更の可否を含む。判断先はアカウント運用側）。配線先: repo-doc:public-form-verification/docs/project-record.md（課題・問題の1件目）
