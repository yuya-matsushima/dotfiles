#!/bin/sh

# Linux (omarchy / Arch) 向け fcitx5 の IM 構成 (profile) を配置する。
# ime-toggle と 英数 / かな バインドは IM が keyboard-us + mozc であることを前提にする。
# fcitx5 は終了時に profile を書き戻すため symlink にはせず, mozc 未登録の場合だけ
# リポジトリのテンプレートをコピーする (既存の構成は *.bak.<timestamp> へ退避)。

set -e

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TEMPLATE="$SCRIPT_DIR/../../omarchy/.config/fcitx5/profile"
PROFILE="${XDG_CONFIG_HOME:-$HOME/.config}/fcitx5/profile"

if [ -f "$PROFILE" ] && grep -qx 'Name=mozc' "$PROFILE"; then
    echo "fcitx5.sh: mozc is already configured in $PROFILE"
    exit 0
fi

mkdir -p "$(dirname -- "$PROFILE")"
if [ -f "$PROFILE" ]; then
    BACKUP="$PROFILE.bak.$(date +%Y%m%d%H%M%S)"
    mv "$PROFILE" "$BACKUP"
    echo "fcitx5.sh: backup: $PROFILE -> $BACKUP"
fi
cp "$TEMPLATE" "$PROFILE"
echo "fcitx5.sh: installed $PROFILE"

# 起動中の fcitx5 に読み直させる (未起動なら次回起動時に反映される)
if fcitx5-remote --check >/dev/null 2>&1; then
    fcitx5-remote -r
fi
