# Yazi File Manager 設定追加計画

## ステータス: 完了

**実装日**: 2025-12-24
**ブランチ**: feature/add-yazi

## 概要

yazi ファイルマネージャーと依存ツール（zoxide, poppler, resvg など）の設定を dotfiles リポジトリに追加します。

## 背景

### Yazi とは

Yazi は Rust で書かれた高速なターミナルファイルマネージャーです。以下の特徴があります：

- 非同期 I/O による高速動作
- 画像プレビューのビルトインサポート
- Vim ライクなキーバインド
- モダンな CLI ツール（fd, ripgrep, zoxide, fzf）との統合

### インストール済み依存ツール

すべての依存ツールは既にコミット ed779f6 と 65001c8 で追加済みです：

- `yazi`: メインのファイルマネージャー
- `ffmpeg`: 動画プレビュー
- `imagemagick`: 画像プレビュー
- `poppler`: PDF プレビュー
- `resvg`: SVG プレビュー
- `sevenzip`: アーカイブプレビュー
- `font-symbols-only-nerd-font`: ターミナルアイコン表示
- `zoxide`: スマートディレクトリジャンプ（yazi と統合）

## 設定構造

```
.config/yazi/
├── yazi.toml      # メイン設定
├── keymap.toml    # カスタムキーバインド（デフォルト使用）
└── theme.toml     # テーマ設定（デフォルト使用）

.zsh/
└── yazi.zsh       # シェル統合とラッパー関数
```

## 実装内容

### 1. Yazi 設定ファイル

#### .config/yazi/yazi.toml

最小限の設定で、隠しファイル表示とディレクトリ優先ソートを有効化：

```toml
# Yazi configuration
# See: https://yazi-rs.github.io/docs/configuration/yazi

[mgr]
# Show hidden files by default
show_hidden = true
# Sort directories first
sort_dir_first = true

[preview]
# Enable image preview
image_quality = 90
```

#### .config/yazi/keymap.toml

空ファイル（デフォルトのキーバインドを使用、将来のカスタマイズ用）：

```toml
# Custom keybindings
# See: https://yazi-rs.github.io/docs/configuration/keymap
# Currently using defaults - add custom bindings here as needed
```

#### .config/yazi/theme.toml

空ファイル（デフォルトテーマを使用、将来のカスタマイズ用）：

```toml
# Theme configuration
# See: https://yazi-rs.github.io/docs/configuration/theme
# Currently using defaults - add custom theme here as needed
```

### 2. シェル統合

#### .zsh/yazi.zsh

yazi でディレクトリを移動して終了時に現在のディレクトリを変更する `y` 関数：

```bash
# Yazi configuration

# Shell wrapper function for changing directory on exit
# Official recommended function from yazi documentation
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

# Alternative: Use yy as an alias if preferred (commented out by default)
# alias yy='y'
```

### 3. .zshrc 変更

**変更1**: zoxide 初期化（line 143 の direnv の後）

```bash
(( $+commands[zoxide] )) && eval "$(zoxide init zsh --cmd cd)"
```

**注**: `--cmd cd` オプションで、`cd` コマンド自体が zoxide の機能を持つようになります。

**変更2**: yazi.zsh 読み込み（line 168-171 の fzf ブロックの後）

```bash
if (( $+commands[yazi] )); then
  [ -f "$HOME/.zsh/yazi.zsh" ] && source "$HOME/.zsh/yazi.zsh"
fi
```

### 4. bin/link.sh 変更

TARGETS 配列に `.config/yazi` を追加（`.config/nvim` の後）

### 5. 依存ツールの設定

#### 設定が必要なツール

- **zoxide**: `.zshrc` でシェル統合が必要（`eval "$(zoxide init zsh --cmd cd)"`）
  - `cd` コマンドが zoxide のスマート機能を持つ

#### 設定不要なツール（自動検出）

- **poppler**: PDF プレビュー（yazi が自動検出）
- **resvg**: SVG プレビュー（yazi が自動検出）
- **ffmpeg, imagemagick, sevenzip, font**: 追加設定不要

## 使用方法

### 基本的な使い方

```bash
# yazi を開く
yazi

# yazi で移動 + 終了時にディレクトリ変更（推奨）
y

# cd コマンドでスマートジャンプ（zoxide 統合）
cd project    # 履歴から部分一致でジャンプ
cd dot        # dotfiles へジャンプ

# yazi と組み合わせて使う
cd project && y

# fzf で対話的にディレクトリ選択
cdi
```

### yazi 内のキーバインド（デフォルト）

- `j/k`: 上下移動
- `h/l`: 親/子ディレクトリへ移動
- `gg/G`: 最上部/最下部
- `f`: ファイル検索
- `z`: zoxide ジャンプ
- `q`: 終了（`y` 関数使用時はディレクトリ変更）
- `Q`: 終了（ディレクトリ変更なし）

### cd コマンド（zoxide 統合）

zoxide は `cd` コマンドと統合されています：

```bash
# 通常の cd と同じ動作
cd /path/to/directory
cd ../..
cd ~

# スマートジャンプ（一度訪れたディレクトリへ部分一致）
cd documents  # → ~/Documents へジャンプ
cd proj       # → よく訪れる project ディレクトリへ
cd dot        # → dotfiles へジャンプ

# fzf を使った対話的選択（cd + i）
cdi

# cd でジャンプしてから yazi で探索
cd proj && y
```

**履歴の確認**:
```bash
# 訪れたディレクトリ一覧（スコア順）
zoxide query -l

# スコア付きで表示
zoxide query -ls
```

**データベースの場所**: `~/.local/share/zoxide/db.zo`

## テスト手順

- [ ] シンボリックリンク作成: `make link`
- [ ] シェル再読み込み: `source ~/.zshrc`
- [ ] yazi 起動確認: `yazi`
- [ ] ディレクトリ移動確認: `y` でyaziを起動、移動後 `q` で終了、PWD が変わることを確認
- [ ] zoxide 動作確認: `cd <dir>` でディレクトリジャンプ
- [ ] fzf 統合確認: `cdi` で対話的ディレクトリ選択
- [ ] プレビュー確認: 画像、PDF、動画が yazi でプレビューされることを確認
- [ ] エラーなし確認: `source ~/.zshrc` でエラーが出ないことを確認

## ファイル一覧

### 新規作成（5ファイル）

- `.config/yazi/yazi.toml`
- `.config/yazi/keymap.toml`
- `.config/yazi/theme.toml`
- `.zsh/yazi.zsh`
- `docs/plans/add-yazi.md`

### 変更（2ファイル）

- `.zshrc` - 2箇所に追加（zoxide 初期化、yazi.zsh 読み込み）
- `bin/link.sh` - TARGETS 配列に1行追加

## 設計判断

### なぜ `.zsh/yazi.zsh` を分離？

- fzf と同じパターンで一貫性を保つ
- `.zshrc` をシンプルに保つ
- 機能拡張しやすい

### なぜ `y` 関数？

- yazi 公式ドキュメントの推奨方法
- 短くてタイプしやすい
- `yy` エイリアスもオプションで提供（コメントアウト）

### なぜ最小限の設定？

- yazi のデフォルトが優秀
- 必要に応じて段階的に追加可能
- メンテナンス負荷を減らす

### zoxide を `cd` と統合した理由

- **直感的**: 新しいコマンド（`z`）を覚える必要がない
- **シームレス**: 既存の `cd` の動作を完全に保ちつつ、スマート機能が追加される
- **学習コスト削減**: `cd` だけ使えばいい
- **fzf 統合**: `cdi` で対話的選択が可能

### zoxide の配置

- direnv の後に配置（両方ともディレクトリ関連ツール）
- fzf の前に配置（zoxide が fzf と統合できる `cdi` コマンド）
- compinit (line 114) の後に配置（必須）

## 既存パターンとの整合性

この実装は既存の dotfiles パターンに従っています：

1. **XDG Config パターン**: `.config/yazi/`（alacritty, ghostty, nvim と同様）
2. **シェル設定パターン**: `.zsh/yazi.zsh`（fzf.zsh と同様）
3. **条件付き読み込み**: `(( $+commands[yazi] ))`（direnv, fzf と同様）
4. **シンボリックリンク管理**: `bin/link.sh` の TARGETS に追加
5. **ドキュメント**: 詳細な計画ドキュメント

## 既知の制限事項

1. **画像プレビュー**: 画像プロトコル対応ターミナルが必要（Alacritty, Ghostty, Kitty, iTerm2）
2. **`yy` 関数なし**: 公式ドキュメントに従い `y` を使用（必要に応じてエイリアス可能）
3. **最小設定**: 必要最小限の設定でスタート（後から拡張可能）

## 将来の拡張

### オプション改善

1. **カスタムテーマ**: ターミナルカラーに合わせたテーマ作成
2. **カスタムキーバインド**: プロジェクト固有のショートカット追加
3. **プラグイン設定**: Yazi は Lua プラグインをサポート
4. **Git 統合**: ファイルリストでの Git ステータス表示強化
5. **アーカイブプレビュー**: 7z 統合の改善

## ロールバック方法

問題が発生した場合：

1. **シンボリックリンク削除**: `bin/link.sh unlink` または `rm ~/.config/yazi`
2. **.zshrc 変更削除**: 追加した2行を削除（zoxide init, yazi.zsh source）
3. **bin/link.sh 変更削除**: TARGETS から `.config/yazi` を削除
4. **インストール保持**: yazi と依存ツールはインストールされたまま

## 参考リンク

- [Yazi Documentation](https://yazi-rs.github.io/)
- [Yazi Configuration](https://yazi-rs.github.io/docs/configuration/yazi)
- [Yazi Quick Start](https://yazi-rs.github.io/docs/quick-start)
- [Zoxide GitHub](https://github.com/ajeetdsouza/zoxide)
