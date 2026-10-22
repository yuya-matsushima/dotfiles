## dotfiles

このリポジトリは Yuya MATSUSHIMA の個人用 dotfiles を管理しています。
macOS と Linux (Omarchy / Arch) の両方の開発環境構築や設定の自動化を目的としています。

macOS と Linux で設定が本質的に異なるものだけを `omarchy/` 配下に OS 別定義として
置き、それ以外は共通の 1 ファイルで管理します (`bin/link.sh` が `uname` で解決)。

## コーディングスタイル

- ターミナルアプリは Ghostty がメインで、Alacritty から移行中です。
- Zsh 上で Tmux を使って作業します。
- CLI 上でもリッチな配色より、シンプルで見やすい表示を好みます。
- テキストエディタは Neovim をメインに使用し、互換性のため Vim 設定も保持しています。
- Vim キーバインドを多用します (Zsh, Tmux, Neovim など)。
- よく使うアプリケーションには Hammerspoon でキーボードショートカットを割り当てています。
- 旧来のコマンドは eza や dexide のような Rust 製アプリへ置き換える方針で、メリットがある場合は新しいツールを積極的に採用します。

## Submodule について

このリポジトリは private submodule を含んでいます。

### 初回クローン時

```sh
git clone --recursive git@github.com:yuya-matsushima/dotfiles.git
```

### 既存のクローンに submodule を取得

```sh
git submodule update --init --recursive
```

## セットアップ

```sh
# for Main Machine (macOS)
make setup

# for Dev Machine (macOS)
make setup_develop

# for Linux (Omarchy / Arch)
make omarchy
```

`make omarchy` は CLI ツールの導入とログインシェルの zsh 化を行い、その後
`make link` を実行します。既に実体ファイルがある設定は `*.bak.<timestamp>` へ
退避してから symlink します。

詳細 (zsh 導入・`chsh` の注意点・OS 別オーバーレイ) は [docs/omarchy.md](docs/omarchy.md) を参照してください。

## コーディングエージェントの共通設定例

Claude Code と Codex は、認証・端末固有パス・プロジェクト履歴などを実設定に
保持するため、設定ファイル全体を symlink しません。dotfiles では、別環境でも
利用できる共通部分だけを次の設定例として管理します。

- `.claude/settings.example.json`
- `.codex/config.example.toml`
- `.codex/hooks.example.json`

これらは `bin/link.sh` の対象外です。ホストの `~/.claude/settings.json` と
`~/.codex/config.toml` は各マシンの実ファイルとして維持します。hooks や
statusline のように端末固有情報を含まない既存設定は、従来どおり symlink します。
OpenCode は Linux でのみ使い, 共通設定 (`.config/opencode`) の symlink も
Linux に限ります (macOS では link せず, Homebrew でも導入しません)。

Pi も Linux でのみ使います。`~/.pi/agent` 全体は symlink せず、認証 (`auth.json`)、
セッション (`sessions/`)、導入済みパッケージ (`npm/`) は端末固有のため各マシンの実
ファイルとして維持し、共通部分だけを symlink します。Pi を使わない macOS では
これらも link しません。

- `.pi/agent/settings.json` (既定プロバイダー/モデル, `packages`)
- `.pi/agent/keybindings.json` (`pi-vim` 用のキーバインド)
- `.pi/agent/AGENTS.md` (グローバル指示。日本語で回答する方針など)
- `.pi/agent/extensions/tmux-status.ts` (tmux ステータス + 通知音のブリッジ)
- `.pi/agent/extensions/guard-force-push.ts` (共有ロジックを使う force-push ガード)
- `.pi/agent/extensions/pi-permission-system/config.json` (権限ポリシー)

`pi` 本体は Linux では mise (`omarchy/.config/mise/config.toml` の `pi = "latest"`)
で管理します (macOS では使いません)。
認証は `OPENCODE_API_KEY` 環境変数か、`pi` 内の `/login` で設定します。
`settings.json` の `packages` で宣言した拡張 (`pi-vim`, `pi-web-search`,
`pi-mcp-adapter` など) は初回起動時に自動導入されます。

`pi-code` は内包する subagent / plan-mode / MCP flag / web search が既存拡張
(`pi-subagents` / `@narumitw/pi-plan-mode` / `pi-mcp-adapter` / `pi-web-search`) と
衝突するため, `packages` の object 形式で該当 extension だけ除外して読み込みます。
`pi-web-access` は `pi-web-search` と `web_search` が重複するため導入しません。

tmux ステータスと通知音は `make agent_hooks` の対象に含まれます。Pi 側は
`~/.pi/agent/extensions/*.ts` が自動で読み込まれるため、登録作業は不要です。
