#!/bin/sh
# ============================================================================
# force-push-reason.sh
#
# guard-force-push (Claude Code / Codex / Pi) が共用する verdict → 理由文言の
# 唯一の出所。判定ロジックの `force-push-verdict.sh` と対になる。
#
# 各アダプタは本スクリプトの出力を自分のプラットフォームの block JSON に包む
# だけにし、文言を各ファイルへコピーしない (3 エージェント間のドリフト防止)。
#
# 入力:
#   第 1 引数に verdict (combined / raw / mirror / plus)。
#   verdict の一覧と意味は force-push-verdict.sh を参照。
#
# 出力:
#   stdout に理由文言を 1 行。終了コードは常に 0。
#   未知の verdict は fail-closed のため汎用文言を返す (判定に新種が増えても
#   アダプタが無言で素通ししない)。
#
# 使い方:
#   reason=$(sh force-push-reason.sh "$verdict")
# ============================================================================

# shellcheck disable=SC2016  # 文言内の backtick は markdown 装飾で意図的
set -eu

case "${1:-}" in
    combined)
        printf '%s\n' 'raw --force と --force-with-lease の併記は意図が矛盾するためブロックします。--force-with-lease 単独に絞ってください。'
        ;;
    raw)
        printf '%s\n' '`git push --force` (or -f / -uf など短縮結合形) is blocked. Prefer `git push --force-with-lease` after confirming with the user, or update the branch via rebase + PR review instead.'
        ;;
    mirror)
        printf '%s\n' '`git push --mirror` は全 ref を上書きするためブロックします。個別 branch を明示的に push してください。'
        ;;
    plus)
        printf '%s\n' '`+<refspec>` による強制更新はブロックします。lease 付きで push するか, rebase + PR review を経由してください。'
        ;;
    *)
        printf '%s\n' "未知の強制更新判定 (${1:-empty}) のためブロックします。コマンドを手動で確認してください。"
        ;;
esac
