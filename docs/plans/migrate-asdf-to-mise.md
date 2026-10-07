# asdf → mise 移行プラン

## 概要

ランタイム管理を asdf (0.20.2, Homebrew) から mise (Homebrew stable 2026.9.x) へ移行する。
本ドキュメントは調査結果と実装手順をまとめたもので、実装担当 (Sonnet) はこの順に作業する。

- ブランチ: `refactor/asdf-to-mise` (作成済み)
- 方針: **移行ではバージョンを変えない**。現在 `~/.tool-versions` で有効なバージョンをそのまま mise に移す。バージョン更新は別タスク。(実装中に方針変更: 決定事項 5, 7 により node 以外は最新版を使う)
- 方針: グローバル設定は `~/.config/mise/config.toml` を **リポジトリで宣言的に管理** し、symlink で配置する (`bin/asdf/*.sh` の命令的インストールを廃止)。
- 方針: `~/.asdf` (31GB) は Phase 2 完了から 2 週間の並行期間を置いてから削除する。
- 方針: java (と java 前提の gradle) は移行対象から外し、廃止する。
- 方針: global npm パッケージは config.toml に `npm:` backend で宣言して管理する (手動 `npm i -g` は廃止)。
- 方針: hugo / checkov / goreleaser / trivy は global に入れない (プロジェクトの `.tool-versions` 経由で必要時に入る)。

## 調査結果

### A. リポジトリ内の asdf 依存 (このリポジトリで変更できる範囲)

| ファイル | 内容 | 対応 |
| --- | --- | --- |
| `bin/asdf/*.sh`, `bin/asdf/aws/sam.sh` | `asdf plugin add` / `install` / `set -u` | 削除し `.config/mise/config.toml` に置換 |
| `Makefile` 49-109, 124, 127 | `asdf_*` ターゲット、`setup` / `setup_develop` | `mise_*` ターゲットへ置換 (後述) |
| `bin/homebrew/cli.sh` 8 | `asdf` を brew install | `mise` に置換 |
| `bin/link.sh` 19 | `.asdfrc` を link | 削除し `.config/mise/config.toml` を追加 |
| `.asdfrc` | `legacy_version_file = yes` | 削除 (mise の `idiomatic_version_file_enable_tools` に移行) |
| `.zshenv` 53 | `${ASDF_DATA_DIR:-$HOME/.asdf}/shims` を PATH へ | `${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims` に置換 |
| `.zshrc` 185-188 / `.zshrc.minimal` 111-114 | `asdf.sh` を source | `eval "$(mise activate zsh)"` に置換 |
| `.zshrc` 203 / `.zshrc.minimal` 129 | `ASDF_GOLANG_MOD_VERSION_ENABLED=true` | 削除 (mise の go idiomatic 設定で代替) |
| `.zshrc` 280 / `.zshrc.minimal` 171 | `.zsh/asdf_completion.zsh` を source | `mise_completion.zsh` にリネームして参照更新 |
| `.zsh/asdf_completion.zsh` | `.asdf/shims/` パス判定、`asdf current gcloud`、`~/.asdf/installs/gcloud/...` | mise 用に書き換え (後述) |
| `.config/nvim/lua/config/options.lua` 10-17 | `ASDF_NODEJS_VERSION=lts asdf where nodejs` | `mise -C ~ where node` に置換 |
| `.config/nvim/ginit.vim` 2-3 | `~/.asdf/shims` を PATH へ | `~/.local/share/mise/shims` に置換 |
| `.config/nvim/lua/plugins/copilot.lua` 16 | コメントのみ | 文言更新 |
| `AGENTS.md` 17, 26, 29 / `.github/copilot-instructions.md` 16, 29, 51, 117 | ドキュメント | mise 表記に更新 |
| `_.gitignore` 9 | `.tool-versions` を global ignore | 残す。`mise.local.toml` / `.mise.local.toml` を追加 |

### B. リポジトリ外 (HOME) の asdf 依存

| 対象 | 状態 | 対応 |
| --- | --- | --- |
| `~/.tool-versions` (実ファイル, 17 ツール) | グローバルバージョン定義 | config.toml に移植後 **削除必須** (後述の注意点 1) |
| `~/.asdfrc` | repo への symlink | `.asdfrc` を TARGETS から外すと `make unlink` で消えないため手動 `rm` |
| `~/.asdf` (31GB) | 21 plugin / 多数の旧バージョン | 動作確認後に削除 |
| `~/Project` 配下の `.tool-versions` × 18 | nodejs / golang / terraform / pnpm / tflint / ruby / python / checkov / goreleaser / trivy / hugo / aws-sam-cli / golangci-lint | ファイルはそのまま (mise が読む)。各プロジェクトで `mise install` が必要 |
| `~/Project` 配下の `.nvmrc` / `.node-version` / `.ruby-version` / `.python-version` | asdf の legacy_version_file で読まれていた | mise の idiomatic 設定を有効化しないと無視される |
| node (lts=24 系) の global npm パッケージ | `@openai/codex`, `@github/copilot`, `ccusage`, `@mermaid-lint/cli` (`@google/gemini-cli` は antigravity-cli に統合されたため宣言しない。決定事項 8) | config.toml に `npm:` backend で宣言 (後述の注意点 5)。`@inkdropapp/mcp-server` は利用していないため宣言しない (決定事項 6) |
| python 3.12.6 の pip パッケージ | `markitdown`, `playwright`, `magika`, `youtube_transcript_api`, `markdownify`, `mammoth` 等 | 再インストール (uv tool 化も検討) |
| `~/.zprofile`, `~/.zshrc_local`, `~/.config/*`, `~/.claude.json`, `~/.claude/settings*.json`, `~/.codex/config.toml`, LaunchAgents, crontab, `~/.local/bin` | asdf 参照 **なし** を確認済み | 対応不要 |
| `.envrc` (`use asdf`) | 該当なし | 対応不要 |

### C. mise registry での対応状況 (確認済み)

全ツールが registry にあり、asdf プラグインを使わず core / aqua backend で入る。

| asdf plugin 名 | mise 名 | backend |
| --- | --- | --- |
| nodejs | node | core |
| python / ruby | 同名 | core |
| golang | go | core |
| rust | rust | core (rustup を使用) |
| awscli | aws-cli (alias: awscli) | aqua |
| aws-sam-cli | aws-sam (alias: aws-sam-cli) | aqua |
| gcloud | gcloud | vfox:mise-plugins/vfox-gcloud |
| kubectl / kubectx / kubeval / terraform / tflint / golangci-lint / hugo / pnpm / checkov / goreleaser / trivy | 同名 | aqua |

## 移行時の注意点

1. **`~/.tool-versions` を残すと global config より優先される**。mise は cwd から上位ディレクトリの `.tool-versions` を読むため、HOME 直下の `.tool-versions` は `~/.config/mise/config.toml` より優先度が高い local 設定として扱われる。移植後は必ず削除 (退避) する。
2. **idiomatic version file はデフォルト無効**。asdf の `legacy_version_file = yes` 相当として `idiomatic_version_file_enable_tools = ["node", "ruby", "python", "go"]` を設定する。go を入れることで `ASDF_GOLANG_MOD_VERSION_ENABLED` の代替 (go.mod の `toolchain` / `go` directive) になる。
3. **`.tool-versions` 内の `nodejs` / `golang` 表記**。registry 上 node / go に alias 定義は無いため、プロジェクトの `.tool-versions` (nodejs 7 件, golang 8 件) が解決されるか実機で確認する (`cd <project> && mise ls`)。解決されない場合はプロジェクト側を `node` / `go` に書き換える必要がある (ただしそれらは各リポジトリの変更なので、本 PR の範囲外として別途ユーザーに報告)。
4. **`mise use -g` は symlink 先 (= repo の config.toml) を書き換える**。これは宣言的管理として意図通りだが、`git status` に差分が出ることを AGENTS.md に明記する。
5. **global npm / pip パッケージは移らない**。codex / gemini などエージェント CLI が asdf の node lts 配下にあるため、移行直後に PATH から消える。config.toml の `npm:` backend で宣言し `mise install` で入れ直す。
   - `@github/copilot` は Homebrew cask `copilot-cli` (`bin/homebrew/cli.sh`) と重複しているため宣言しない (brew 版に一本化)。
   - `/opt/homebrew/bin/ccusage` は Homebrew の node に `npm i -g` された古いもの (2025-06)。mise 版と PATH 上で競合しうるので削除する (ユーザー承認済み)。Phase 2 で brew node 側から `/opt/homebrew/bin/npm uninstall -g ccusage` を実行する。
   - npm backend のツールは shebang が `#!/usr/bin/env node` のため、**実行時は PATH 上の node で動く**。古い node を指定したプロジェクト (例: node 16) 内では動かない可能性がある (asdf 時代と同条件のためユーザー了承済み、対応不要)。
   - `latest` 指定のため更新は `mise upgrade` (config は `latest` のまま)。
6. **ruby / python / node の旧バージョンはバイナリ流用不可**。`~/.asdf/installs` 配下はパスがハードコードされているため mise 側で再インストールする。ruby 2.7 系など古いバージョンは現行 macOS / OpenSSL でビルド失敗の可能性がある (プロジェクト側の問題として報告のみ)。
7. **python は mise ではデフォルトで precompiled (python-build-standalone)**。asdf (python-build でソースビルド) と挙動が異なる。問題があれば `python.compile = true`。また 3.12.6 は GitHub artifact attestation が無く検証失敗でインストールできなかったため、検証は無効化せずバージョンを最新版に上げた (決定事項 5, 7)。
8. **rust は rustup ベース**。mise core rust は `~/.rustup` / `~/.cargo` (`RUSTUP_HOME` / `CARGO_HOME`) を使う。現状どちらも存在しないため衝突はない。
9. **java / gradle は廃止**。java は移行しない。gradle は java が無いと動かないため併せて外す。`~/.asdf` 削除とともに消えるので、以後必要になったらプロジェクト側の設定で入れる。
10. **shims と activate の併用**。`.zshenv` の shims は非対話シェル (Claude Code / VimR / nvim の外部コマンド) 用、`.zshrc` の `mise activate` は対話シェル用。`.zshrc` 内の `(( $+commands[go] ))` / `pnpm` 判定は activate 前でも shims で解決されるので順序は現状維持でよい。
11. **zcompile**。`.zshrc` / `.zshenv` は起動時に zcompile されるので、変更後は新しいシェルを開いて確認する (`.zwc` が古いまま読まれないこと)。
12. **並行期間の PATH 競合**。asdf と mise の shims が同時に PATH にあると優先順で意図しないバイナリが使われる。`.zshenv` からは asdf shims を完全に外す (併記しない)。

## 実装手順

### Phase 1: リポジトリ変更 (Sonnet 担当)

1. `.config/mise/config.toml` を新規作成。

   ```toml
   [settings]
   # asdf の legacy_version_file = yes 相当 + ASDF_GOLANG_MOD_VERSION_ENABLED 相当
   idiomatic_version_file_enable_tools = ["node", "ruby", "python", "go"]

   [tools]
   # node は LTS、それ以外は最新版を使う。kube 系は未使用のため宣言しない
   node = "lts"
   pnpm = "latest"
   ruby = "latest"
   python = "latest"
   go = "latest"
   golangci-lint = "latest"
   rust = "latest"
   aws-cli = "latest"
   gcloud = "latest"
   aws-sam = "latest"
   terraform = "latest"
   tflint = "latest"
   # global npm パッケージ (旧: asdf node lts への npm i -g)
   # @github/copilot は Homebrew cask copilot-cli に一本化
   "npm:@openai/codex" = "latest"
   "npm:ccusage" = "latest"
   "npm:@mermaid-lint/cli" = "latest"
   ```

   - java / gradle は廃止のため含めない。hugo は global に入れないため含めない (`asdf_hugo` / `asdf_java` ターゲットは後継を作らず削除)。
   - 実装前に `~/.tool-versions` を再確認し、差分があれば最新に合わせる。
   - `latest` 指定では `mise install` は導入済みの旧バージョンを使う。最新版への更新は `mise upgrade` で行う。

2. `bin/link.sh`: TARGETS から `.asdfrc` を削除し `.config/mise/config.toml` を追加 (ファイル単位で link。dir ごと link すると mise の他ファイルが repo に入るため)。
3. `.asdfrc` を削除。
4. `bin/asdf/` ディレクトリを削除。
5. `Makefile`: `asdf_*` を以下に置換。

   <!-- markdownlint-disable MD010 -->
   ```make
   .PHONY: mise
   mise: ## Install all tools defined in mise config
   	mise install
   	mise exec -- sh ./bin/languages/golang.sh

   .PHONY: mise_langs
   mise_langs: ## Install languages
   	mise install node pnpm ruby python go golangci-lint rust
   	mise exec -- sh ./bin/languages/golang.sh

   .PHONY: mise_infra
   mise_infra: ## Install infra tools
   	mise install aws-cli gcloud aws-sam terraform tflint

   .PHONY: mise_upgrade
   mise_upgrade: ## Upgrade mise tools to latest
   	mise upgrade
   ```
   <!-- markdownlint-enable MD010 -->

   - `setup_develop` の `asdf_ruby asdf_python asdf_cloud` → `mise install node ruby python aws-cli gcloud` 相当のターゲット (`mise_develop` など) に置換。
   - `setup` の `asdf` → `mise`。
   - `bin/languages/golang.sh` (goimports) は go が PATH にある前提。`mise install` 直後は shims 経由で解決されるので `mise exec -- sh ./bin/languages/golang.sh` にしておくと確実。
6. `bin/homebrew/cli.sh`: `asdf` → `mise`。
7. `.zshenv`: shims パスを `${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims` に置換。
8. `.zshrc` / `.zshrc.minimal`:
   - asdf ブロックを `(( $+commands[mise] )) && eval "$(mise activate zsh)"` に置換。
   - `ASDF_GOLANG_MOD_VERSION_ENABLED` 行を削除。
   - completion の source 先を `mise_completion.zsh` に変更。
9. `.zsh/asdf_completion.zsh` → `.zsh/mise_completion.zsh` に `git mv` し書き換え。
   - `.asdf/shims/` のパス判定を廃止し、`(( $+commands[aws_completer] ))` / `(( $+commands[terraform] ))` で判定。
   - gcloud は `gcloud_path=$(mise where gcloud 2>/dev/null)` で取得し `path.zsh.inc` / `completion.zsh.inc` を source。vfox-gcloud のインストールレイアウトでこれらのファイルがどこにあるか実機で確認して合わせる。
   - 先頭の `(( $+commands[asdf] ))` ガードを mise に変更。
10. `.config/nvim/lua/config/options.lua`: `ASDF_NODEJS_VERSION=lts asdf where nodejs` → `mise -C ~ where node` (global の node を取得。プロジェクトの古い node を避ける目的は維持)。変数名 `asdf_node_path` とコメントも更新。
11. `.config/nvim/ginit.vim`: `~/.asdf/shims` → `~/.local/share/mise/shims`、コメント更新。
12. `.config/nvim/lua/plugins/copilot.lua`: コメントの asdf → mise。
13. `_.gitignore`: `mise.local.toml`, `.mise.local.toml` を追加。
14. `AGENTS.md`, `.github/copilot-instructions.md`: asdf 記述を mise に更新。`make asdf_update` → `make mise_upgrade`、`bin/asdf/` の記述削除、config.toml が repo 管理で `mise use -g` が repo を書き換える旨を追記。
15. 最終確認: `git grep -n -i asdf -- ':!docs/plans'` がヒット 0 件であること。

### Phase 2: HOME 側の移行 (ユーザー確認のうえ実行)

1. `brew install mise`
2. `mv ~/.tool-versions ~/.tool-versions.asdf-backup`
3. `rm ~/.asdfrc` (symlink) → `make link` で `~/.config/mise/config.toml` を配置
   - `~/.config/mise/` が既に実ディレクトリで config.toml が実ファイルとして存在する場合 link.sh はエラーで止まるので確認。
4. 新しいシェルで `mise doctor` / `mise install` を実行。
5. 旧 ccusage を削除: `/opt/homebrew/bin/npm uninstall -g ccusage`。その後 npm backend のツールが入ったことを確認: `which codex ccusage mermaid-lint` が mise 配下を指すこと。`copilot` は brew cask を指すこと。
6. python 3.12.6 の pip パッケージ再インストール (`~/.asdf/installs/python/3.12.6/bin` から一覧を取得)。
7. `~/Project` 配下 18 プロジェクトで `mise install` (一覧は `find ~/Project -maxdepth 4 -name .tool-versions -not -path '*/node_modules/*'`)。
8. Phase 2 完了から 2 週間後、問題がなければ `brew uninstall asdf` と `rm -rf ~/.asdf` (31GB 解放)。**不可逆のため実行前に必ずユーザー確認**。Phase 2 完了日と削除予定日を PR 本文に記載する。

## 検証手順

- `sh -n bin/link.sh`, `sh -n bin/homebrew/cli.sh`, 可能なら `shellcheck`
- `zsh -n .zshrc .zshrc.minimal .zshenv .zsh/mise_completion.zsh`
- 新しい対話シェルでエラーが出ないこと、`source ~/.zshrc` が通ること
- `which node ruby python go terraform aws gcloud` が mise 配下を指すこと、`mise ls` / `mise doctor` に警告がないこと
- 非対話シェル: `zsh -c 'which node go'` が mise shims を指すこと (Claude Code から実行される想定)
- `cd` で各プロジェクトに入り `.tool-versions` / `.nvmrc` / `.ruby-version` のバージョンが反映されること (注意点 3 の `nodejs` / `golang` 表記を含む)
- `aws <TAB>`, `terraform <TAB>`, `gcloud <TAB>` の補完
- nvim: `:!which node` が global node、copilot.lua が起動すること。VimR でも同様
- `make help` に `mise*` ターゲットが表示され `asdf*` が消えていること

## 決定事項 (2026-10-01 ユーザー回答)

1. global npm パッケージは config.toml に `npm:` backend で宣言する (`@github/copilot` は brew cask に一本化)。
   - Homebrew の node に残っている旧 ccusage (`/opt/homebrew/bin/ccusage`) は削除する。
   - npm backend のツールが古い node のプロジェクト内で動かない可能性は許容する。
2. hugo / checkov / goreleaser / trivy は global に入れない。
3. `~/.asdf` は Phase 2 完了の 2 週間後に削除する。
4. java は削除する (gradle も java 前提のため併せて削除)。

## 決定事項 (2026-10-01 実装中の追加判断)

5. python は attestation 検証を無効化せず、`3.12.6` から最新版 `3.14.7` に変更する (「移行ではバージョンを変えない」方針の例外)。ユーザーは最新版または LTS を使っているつもりだったため。
6. `@inkdropapp/mcp-server` は利用していないため、npm 宣言から外して廃止する (週間ダウンロード数が mise の閾値未満で拒否されたことが発覚のきっかけ)。
7. kubectl / kubectx / kubeval は利用していないため config.toml から外す。残りのツールはバージョンを固定せず、node は `lts`、それ以外は `latest` にする (決定事項 5 を全ツールに拡張)。更新は `mise upgrade` で行う。
   - `mise upgrade --bump` は `node = "lts"` を LTS でない最新版 (26.x) に書き換えるため使わない。
8. `@google/gemini-cli` は antigravity-cli に統合されたため、npm 宣言から外して mise 側からも削除する。

## 実施記録

- 2026-10-07: asdf 本体と `~/.asdf` を削除 (#247)。並行期間の満了予定は 2026-10-15 だったが、ユーザー判断で前倒しして実施した。
  - `brew uninstall asdf`
  - `~/.asdf` (約 31GB) を削除 (Go module cache 配下が読み取り専用ディレクトリのため `chmod -R u+w` 後に削除)
  - `~/.tool-versions.asdf-backup` を削除
  - 削除後の確認: `brew list asdf` が失敗し、`which node go ruby python terraform aws gcloud codex ccusage mermaid-lint` がすべて `~/.local/share/mise/shims/` を指し、`mise doctor` が "No problems found" を返す
