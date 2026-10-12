/**
 * tmux-status.ts
 *
 * Pi coding agent の実行状態を tmux の per-pane ステータスと通知音に橋渡しする。
 *
 * 目的:
 *   Claude Code / Codex / OpenCode と同じく、Pi の実行中・承認待ち・待機を
 *   tmux のステータス行 (pane option `@agent_status`) に表示し、承認待ちでは
 *   通知音を鳴らす。
 *
 * 対応関係:
 *   - ステータス更新 : `~/.tmux/agent-status.sh` (Claude / Codex / OpenCode と共用)
 *   - 通知音         : `~/.agents/hooks/notify-sound.sh` (Claude / Codex と共用)
 *   - 承認待ちの検知 : pi-permission-system が発火する
 *                      `permissions:ui_prompt` / `permissions:decision` を利用する
 *
 * 備考:
 *   - 各スクリプトは tmux 外 / macOS 以外では自ら no-op するため、ここでは
 *     環境判定をせず detached で起動する。
 *   - pi-code などで Claude Code の hooks を併用している場合、`Notification`
 *     hook と本拡張の通知音が二重に鳴ることがある。どちらか片方を無効化する。
 */

import { spawn } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const HOME = homedir();
const AGENT_STATUS = join(HOME, ".tmux", "agent-status.sh");
const NOTIFY_SOUND = join(HOME, ".agents", "hooks", "notify-sound.sh");

// スクリプトを切り離して起動する。失敗しても Pi 本体を止めない (best effort)。
function run(script: string, args: string[] = []): void {
    try {
        const child = spawn("sh", [script, ...args], {
            detached: true,
            stdio: "ignore",
        });
        child.on("error", () => {});
        child.unref();
    } catch {
        // best effort
    }
}

export default function (pi: ExtensionAPI) {
    pi.on("session_start", () => {
        run(AGENT_STATUS, ["idle"]);
    });

    pi.on("agent_start", () => {
        run(AGENT_STATUS, ["working"]);
    });

    // agent_settled は「リトライ・compaction・自動継続がすべて落ち着いた」最終地点。
    // 途中の agent_end ではなくこちらで待機に戻す。
    pi.on("agent_settled", () => {
        run(AGENT_STATUS, ["idle"]);
    });

    pi.on("session_shutdown", () => {
        run(AGENT_STATUS, ["clear"]);
    });

    // pi-permission-system の承認ダイアログが開いたら blocked + 通知音、
    // 決定したら working に戻す。
    pi.events.on("permissions:ui_prompt", () => {
        run(AGENT_STATUS, ["blocked"]);
        run(NOTIFY_SOUND);
    });

    pi.events.on("permissions:decision", () => {
        run(AGENT_STATUS, ["working"]);
    });
}
