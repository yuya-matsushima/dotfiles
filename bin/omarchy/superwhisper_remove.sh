#!/bin/sh

# Superwhisper (superwhisper-bin) を Omarchy からきれいに外す。
#
# - systemd user service を停止・無効化
# - dictation backend を superwhisper から hex に切り替え
# - Omarchy バーの superwhisper.panel を無効化して削除
# - superwhisper-bin パッケージを削除
# - 設定・モデル・キャッシュなどのユーザーデータを削除
#
# 使い方:
#   sh bin/omarchy/superwhisper_remove.sh
#   make omarchy_superwhisper_remove
#   make omarchy (通常はこちら)

set -e

if [ "$(uname -s)" != "Linux" ]; then
    echo "superwhisper_remove.sh: this script is for Linux only" >&2
    exit 1
fi

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
SHELL_JSON="$CONFIG_HOME/omarchy/shell.json"

# systemd user service を止める。ユニットが無い場合は何もしない。
if systemctl --user list-unit-files superwhisper.service >/dev/null 2>&1; then
    systemctl --user disable --now superwhisper >/dev/null 2>&1 || true
fi

# dictation backend が superwhisper なら hex に切り替える。
# superwhisper のアダプタが残っているうちに実行する。
if command -v omarchy-default-dictation >/dev/null 2>&1; then
    current=$(omarchy-default-dictation 2>/dev/null || true)
    if [ "$current" = "superwhisper" ]; then
        if command -v omarchy-dictation-use >/dev/null 2>&1 && \
            command -v omarchy-dictation-hex >/dev/null 2>&1; then
            omarchy-dictation-use hex
            echo "superwhisper_remove.sh: dictation backend set to hex"
        else
            rm -f -- "$CONFIG_HOME/omarchy/defaults/dictation"
            echo "superwhisper_remove.sh: cleared the superwhisper dictation backend"
        fi
    fi
fi

# Omarchy バーのパネルを無効化してプラグインの symlink を外す。
# manifest の id は superwhisper.panel だが, ディレクトリ名は superwhisper-panel。
# shell.json を書き換える前に, 対象が残っていれば退避する。
if [ -f "$SHELL_JSON" ] && grep -q 'superwhisper\.panel' "$SHELL_JSON"; then
    cp -p "$SHELL_JSON" "$SHELL_JSON.bak.$(date +%Y%m%d%H%M%S)"
    echo "superwhisper_remove.sh: backed up $SHELL_JSON"
fi

if command -v omarchy-shell >/dev/null 2>&1; then
    omarchy-shell -q shell setPluginEnabled superwhisper.panel false >/dev/null 2>&1 || true
fi

for panel in \
    "$CONFIG_HOME/omarchy/plugins/superwhisper-panel" \
    "$CONFIG_HOME/omarchy/plugins/superwhisper.panel"; do
    if [ -L "$panel" ]; then
        target=$(readlink "$panel" || true)
        case "$target" in
            /opt/superwhisper/* | */superwhisper-panel)
                rm -f -- "$panel"
                echo "superwhisper_remove.sh: removed $panel"
                ;;
        esac
    fi
done

if command -v omarchy-shell >/dev/null 2>&1; then
    omarchy-shell -q shell rescanPlugins >/dev/null 2>&1 || true
fi

# 設定画面・パネル・推論ワーカーなど, systemd 管理外で残ったプロセスを止める。
# パスを /opt/superwhisper に限定して, 他のプロセスを巻き込まないようにする。
if command -v pkill >/dev/null 2>&1; then
    pkill -f '^/opt/superwhisper/' 2>/dev/null || true
    pkill -f '/opt/superwhisper/assets/omarchy-plugin/' 2>/dev/null || true
fi

# shell.json に残った tray / disabledPlugins / plugins の項目を掃除する。
# setPluginEnabled が既に消している場合は何もしない。
if [ -f "$SHELL_JSON" ] && command -v jq >/dev/null 2>&1; then
    tmp=$(mktemp)
    if jq '
        (.bar.layout.tray // []) |= map(select(.id != "superwhisper.panel"))
        | (.disabledPlugins // []) |= map(select(. != "superwhisper.panel"))
        | (.plugins // []) |= map(select(.id != "superwhisper.panel"))
    ' "$SHELL_JSON" >"$tmp"; then
        if ! cmp -s "$SHELL_JSON" "$tmp"; then
            mv -- "$tmp" "$SHELL_JSON"
            echo "superwhisper_remove.sh: removed superwhisper.panel from shell.json"
        else
            rm -f -- "$tmp"
        fi
    else
        rm -f -- "$tmp"
        echo "superwhisper_remove.sh: failed to update $SHELL_JSON" >&2
    fi
fi

# パッケージを削除する (未導入なら何もしない)。
# omarchy pkg drop は pacman -Rns --noconfirm を sudo 付きで実行する。
if command -v pacman >/dev/null 2>&1; then
    packages=$(pacman -Qq 2>/dev/null | grep -E '^superwhisper(-bin)?$' || true)
    if [ -n "$packages" ]; then
        if command -v omarchy >/dev/null 2>&1; then
            # shellcheck disable=SC2086
            omarchy pkg drop $packages
        else
            # shellcheck disable=SC2086
            sudo pacman -Rns --noconfirm $packages
        fi
    else
        echo "superwhisper_remove.sh: superwhisper package is not installed"
    fi
fi

# ユーザーデータを削除する。オフラインモデル (~2.6GB) とクラウド認証情報を含む。
for path in \
    "$CONFIG_HOME/superwhisper" \
    "$DATA_HOME/superwhisper" \
    "$CACHE_HOME/superwhisper" \
    "$STATE_HOME/superwhisper"; do
    if [ -e "$path" ]; then
        rm -rf -- "$path"
        echo "superwhisper_remove.sh: removed $path"
    fi
done

rm -f -- "$CONFIG_HOME/autostart/superwhisper.desktop"
rm -f -- "$DATA_HOME/applications/superwhisper.desktop" \
    "$DATA_HOME/applications/superwhisper-url.desktop"

# アプリが作る ~/.local/bin/superwhisper (パッケージ外) も外す。
if [ -L "$HOME/.local/bin/superwhisper" ]; then
    target=$(readlink "$HOME/.local/bin/superwhisper" || true)
    case "$target" in
        */superwhisper)
            rm -f -- "$HOME/.local/bin/superwhisper"
            ;;
    esac
fi

systemctl --user daemon-reload >/dev/null 2>&1 || true

echo "superwhisper_remove.sh: Superwhisper removal complete"
