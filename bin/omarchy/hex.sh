#!/bin/sh

# Linux (omarchy / Arch) 向け Hex (ローカル音声入力) 導入。
#
# Hex は Arch 公式リポジトリにも AUR にも未収録のため, 公式インストーラを使う。
# インストーラはリリース署名と SHA-256 を検証し, 次のユーザーローカル構成を作る:
#   ~/.local/bin/hex                       (起動用 symlink)
#   ~/.local/share/hex/{current,versions}  (本体。stable channel を自己更新する)
#   ~/.local/share/applications/anomaly.hex.desktop
#   ~/.config/autostart/anomaly.hex.desktop
#   ~/.config/systemd/user/hex.service     (Type=notify。enable はしない)
#
# 使い方: sh bin/omarchy/hex.sh [--force]   (通常は make omarchy / make omarchy_hex 経由)
#   --force: 導入済みでも依存を確認し, 最新版を入れ直す

set -e

if [ "$(uname -s)" != "Linux" ]; then
    echo "hex.sh: this script is for Linux only" >&2
    exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
    echo "hex.sh: install Hex as your desktop user, not root" >&2
    exit 1
fi

HEX_BIN="$HOME/.local/bin/hex"

# Omarchy 4.5 以降は dictation がバックエンド方式。アダプタ
# (omarchy-dictation-hex) が PATH にあれば, 選択中のバックエンドを hex にする。
# 4.0.x にはこの仕組みが無いため何もしない (hypr/bindings.lua が自前で張る)。
select_backend() {
    if ! command -v omarchy-dictation-use >/dev/null 2>&1; then
        return 0
    fi
    if ! command -v omarchy-dictation-hex >/dev/null 2>&1; then
        echo "hex.sh: omarchy-dictation-hex is not linked yet; run 'make link' and re-run this script" >&2
        return 0
    fi
    current=$(omarchy-default-dictation 2>/dev/null || true)
    if [ "$current" = "hex" ]; then
        echo "hex.sh: dictation backend is already hex"
        return 0
    fi
    omarchy-dictation-use hex
    echo "hex.sh: dictation backend set to hex"
}

# 導入済みなら何もしない。Hex は stable channel を自分で更新するため,
# make omarchy のたびにダウンロードし直す必要も, sudo を要求する必要もない。
if [ -x "$HEX_BIN" ] && [ "${1:-}" != "--force" ]; then
    echo "hex.sh: Hex is already installed: $("$HEX_BIN" --version 2>/dev/null || echo unknown)"
    echo "hex.sh: it updates itself; run 'sh bin/omarchy/hex.sh --force' to reinstall."
    select_backend
    exit 0
fi

# 公式インストーラが挙げている実行時依存のうち, omarchy base に無いもの。
# 既に導入済みのパッケージは pacman / omarchy が skip する。
#   openblas: 推論バックエンド
#   tinyxxd: xxd (公式ドキュメントの依存。tinyxxd が提供する)
#   vulkan-intel: MacBookPro16,2 (Intel Iris Plus) 用の Vulkan ドライバ。
#     Hex は CPU 推論でもウィンドウに Vulkan ドライバを要求する
#     (vulkan-icd-loader だけでは動かない)
#
# omarchy base が既に導入するため含めないもの:
#   alsa-lib curl jq libxkbcommon libxkbcommon-x11 libx11 libxcb openssl
#   util-linux wl-clipboard wtype
#   vulkan-icd-loader: vulkan-intel の依存で導入される
install_official() {
    if command -v omarchy >/dev/null 2>&1; then
        omarchy pkg add "$@"
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm "$@"
    else
        echo "hex.sh: no supported package manager (omarchy/pacman) found" >&2
        exit 1
    fi
}

install_official \
    openblas \
    tinyxxd \
    vulkan-intel

# パイプで直接 sh に渡さず, 一度ファイルに落としてから実行する。
installer=$(mktemp)
trap 'rm -f "$installer"' EXIT
curl --proto '=https' --tlsv1.2 -fsSL \
    https://anoma.ly/hex/files/install-linux.sh -o "$installer"
sh "$installer"

select_backend

echo "hex.sh: Hex installed to $HEX_BIN"
echo "hex.sh: next steps:"
echo "  make link && hyprctl reload   # バインドと omarchy-dictation-hex を反映"
echo "  $HEX_BIN                      # 初回起動。音声モデルをダウンロードする"
