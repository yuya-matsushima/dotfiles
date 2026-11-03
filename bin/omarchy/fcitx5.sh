#!/bin/sh

# Linux (omarchy / Arch) 向け fcitx5 の設定を配置する。
# fcitx5 は終了時や設定変更時に profile / config を書き戻すため symlink にはせず,
# 未設定の場合だけ手を入れる (冪等)。
#
# - profile: ime-toggle と 英数 / かな バインドは IM が keyboard-us + mozc であることを
#   前提にする。mozc 未登録の場合だけリポジトリのテンプレートをコピーする
#   (既存の構成は *.bak.<timestamp> へ退避)。
# - config: IME 切替は Hyprland (かな / 英数 / SUPER 単押し) が fcitx5-remote -s で行う。
#   fcitx5 自身のトリガキーが残っていると CTRL + SPACE がアプリ (nvim の補完等) に
#   届かず, また Zenkaku_Hankaku (半角/全角) が active/inactive トグルとして動いて
#   mozc が「直接入力」に取り残されるため, [Hotkey/TriggerKeys] を空にする。
#   4.5 の omarchy-input-method は Control+space を除去しつつ Zenkaku_Hankaku と
#   Hangul を残すので, 空にする処理は引き続き必要 (docs/omarchy.md 参照)。

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

# [Hotkey/TriggerKeys] を空に揃える。上流 (4.5) は Control+space を除去するが
# Zenkaku_Hankaku / Hangul を残すため, キー行があれば削除し, セクション自体が
# 無ければ空セクションを追加する (冪等)。
if [ -f "$CONFIG" ]; then
    TRIGGER_STATE=$(awk '
        /^[[:space:]]*\[Hotkey\/TriggerKeys\][[:space:]]*$/ { seen = 1; in_section = 1; next }
        in_section && /^[[:space:]]*\[/ { in_section = 0 }
        in_section && /^[[:space:]]*[0-9]+[[:space:]]*=/ { has_keys = 1 }
        END { print (seen ? (has_keys ? "keys" : "empty") : "missing") }
    ' "$CONFIG")
else
    TRIGGER_STATE=missing
fi

case "$TRIGGER_STATE" in
    empty)
        echo "fcitx5.sh: trigger keys are already empty in $CONFIG"
        ;;
    keys)
        BACKUP="$CONFIG.bak.$(date +%Y%m%d%H%M%S)"
        cp "$CONFIG" "$BACKUP"
        echo "fcitx5.sh: backup: $CONFIG -> $BACKUP"
        PERM=$(stat -c %a "$CONFIG")
        TMP=$(mktemp "$CONFIG.XXXXXX")
        if ! awk '
            /^[[:space:]]*\[Hotkey\/TriggerKeys\][[:space:]]*$/ { in_section = 1; print; next }
            in_section && /^[[:space:]]*\[/ { in_section = 0 }
            in_section && /^[[:space:]]*[0-9]+[[:space:]]*=/ { next }
            { print }
        ' "$CONFIG" >"$TMP"; then
            rm -f "$TMP"
            echo "fcitx5.sh: failed to rewrite $CONFIG" >&2
            exit 1
        fi
        chmod "$PERM" "$TMP"
        mv "$TMP" "$CONFIG"
        echo "fcitx5.sh: cleared trigger keys in $CONFIG"
        CHANGED=1
        ;;
    *)
        {
            echo ""
            echo "# IME 切替は Hyprland が行うため fcitx5 のトリガキーは空にする (bin/omarchy/fcitx5.sh)"
            echo "[Hotkey/TriggerKeys]"
        } >>"$CONFIG"
        echo "fcitx5.sh: cleared trigger keys in $CONFIG"
        CHANGED=1
        ;;
esac

# 起動中の fcitx5 に読み直させる (未起動なら次回起動時に反映される)
if [ "$CHANGED" -eq 1 ] && fcitx5-remote --check >/dev/null 2>&1; then
    fcitx5-remote -r
fi
