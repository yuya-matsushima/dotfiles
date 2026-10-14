#!/bin/sh
# ============================================================================
# notify-sound.sh
#
# Hook event : Claude Code の Notification / Codex の PermissionRequest
#
# 目的:
#   エージェントが操作待ち（承認要求・エラー等）で止まったときに
#   短い効果音を鳴らし、席を外していても気付けるようにする
#   （macOS: afplay / Linux: pw-play, paplay, canberra-gtk-play）。
#   入力を参照しないため Claude Code と Codex で共用する。
#
# 備考:
#   - preferredNotifChannel: 'ghostty' で ghostty 側のバナー通知も併用中。
#     ghostty 側に音があると二重になるので、音が重複していると感じたら
#     どちらか片方を無効化する。
#   - 再生コマンドをバックグラウンド実行し、hook 全体は即 exit 0（tmux status
#     など後続 hook の遅延を避けるため）。
#
# 入力:
#   stdin の JSON は使わない（通知が発火した事実のみで十分）。
# ============================================================================

set -eu

# macOS: システム音を極小音量で再生
if command -v afplay >/dev/null 2>&1 && [ -f /System/Library/Sounds/Ping.aiff ]; then
  afplay -v 0.05 /System/Library/Sounds/Ping.aiff >/dev/null 2>&1 &
  exit 0
fi

# Linux: PipeWire (pw-play) / PulseAudio (paplay) / libcanberra の順にフォールバック
SOUND="/usr/share/sounds/freedesktop/stereo/complete.oga"
if command -v pw-play >/dev/null 2>&1 && [ -f "$SOUND" ]; then
  pw-play --volume 0.2 "$SOUND" >/dev/null 2>&1 &
  exit 0
fi
if command -v paplay >/dev/null 2>&1 && [ -f "$SOUND" ]; then
  # paplay の --volume は 0...65536 の線形値 (0.2 ≒ 13107)
  paplay --volume=13107 "$SOUND" >/dev/null 2>&1 &
  exit 0
fi
if command -v canberra-gtk-play >/dev/null 2>&1; then
  canberra-gtk-play -i complete >/dev/null 2>&1 &
  exit 0
fi

# 再生手段がない環境では静かに終了
exit 0
