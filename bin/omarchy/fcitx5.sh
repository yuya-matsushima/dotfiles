#!/bin/sh

# Linux (omarchy / Arch) 向け fcitx5 の設定を配置する。
# fcitx5 は終了時や設定変更時に profile / config を書き戻すため symlink にはせず,
# 未設定の場合だけ手を入れる (冪等)。
#
# - profile: ime-toggle と 英数 / かな バインドは IM が keyboard-us + mozc であることを
#   前提にする。mozc 未登録の場合だけリポジトリのテンプレートをコピーする
#   (既存の構成は *.bak.<timestamp> へ退避)。
# - config: IME 切替は Hyprland (かな / 英数 / SUPER 単押し) が fcitx5-remote -s で行う。
#   fcitx5 既定のトリガキー (Control+space 等) が残っていると CTRL + SPACE が
#   アプリ (nvim の補完等) に届かないため, [Hotkey/TriggerKeys] を空にする。

set -e

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
TEMPLATE="$SCRIPT_DIR/../../omarchy/.config/fcitx5/profile"
FCITX5_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fcitx5"
PROFILE="$FCITX5_DIR/profile"
CONFIG="$FCITX5_DIR/config"
CHANGED=0

mkdir -p "$FCITX5_DIR"

if [ -f "$PROFILE" ] && grep -qx 'Name=mozc' "$PROFILE"; then
    echo "fcitx5.sh: mozc is already configured in $PROFILE"
else
    if [ -f "$PROFILE" ]; then
        BACKUP="$PROFILE.bak.$(date +%Y%m%d%H%M%S)"
        mv "$PROFILE" "$BACKUP"
        echo "fcitx5.sh: backup: $PROFILE -> $BACKUP"
    fi
    cp "$TEMPLATE" "$PROFILE"
    echo "fcitx5.sh: installed $PROFILE"
    CHANGED=1
fi

# コメントアウトされていない [Hotkey/TriggerKeys] があれば設定済みとみなす。
# 空のセクションを置くと fcitx5 はトリガキー無し (空リスト) として扱う。
if [ -f "$CONFIG" ] && grep -qx '\[Hotkey/TriggerKeys\]' "$CONFIG"; then
    echo "fcitx5.sh: trigger keys are already configured in $CONFIG"
else
    {
        echo ""
        echo "# IME 切替は Hyprland が行うため fcitx5 のトリガキーは空にする (bin/omarchy/fcitx5.sh)"
        echo "[Hotkey/TriggerKeys]"
    } >>"$CONFIG"
    echo "fcitx5.sh: cleared trigger keys in $CONFIG"
    CHANGED=1
fi

# 起動中の fcitx5 に読み直させる (未起動なら次回起動時に反映される)
if [ "$CHANGED" -eq 1 ] && fcitx5-remote --check >/dev/null 2>&1; then
    fcitx5-remote -r
fi
