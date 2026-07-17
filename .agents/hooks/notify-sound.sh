#!/bin/sh
# ============================================================================
# notify-sound.sh
#
# Hook event : Claude Code の Notification / Codex の PermissionRequest
#
# 目的:
#   エージェントが操作待ち（承認要求・エラー等）で止まったときに
#   macOS の afplay で短い効果音を鳴らし、席を外していても気付けるようにする。
#   入力を参照しないため Claude Code と Codex で共用する。
#
# 備考:
#   - preferredNotifChannel: 'ghostty' で ghostty 側のバナー通知も併用中。
#     ghostty 側に音があると二重になるので、音が重複していると感じたら
#     どちらか片方を無効化する。
#   - afplay をバックグラウンド実行し、hook 全体は即 exit 0（tmux status
#     など後続 hook の遅延を避けるため）。
#
# 入力:
#   stdin の JSON は使わない（通知が発火した事実のみで十分）。
# ============================================================================

set -eu

# 存在しない環境（macOS 以外や afplay 未インストール）では静かに終了
command -v afplay >/dev/null 2>&1 || exit 0

# Glass はデフォルトで存在する短めのシステム音
SOUND="/System/Library/Sounds/Ping.aiff"
[ -f "$SOUND" ] || exit 0

afplay "$SOUND" >/dev/null 2>&1 &

exit 0
