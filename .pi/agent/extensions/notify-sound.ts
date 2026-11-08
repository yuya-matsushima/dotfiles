/**
 * notify-sound.ts
 *
 * Pi coding agent の承認待ちで通知音を鳴らす。
 *
 * 対応関係:
 *   - 通知音         : `~/.agents/hooks/notify-sound.sh` (Claude / Codex と共用)
 *   - 承認待ちの検知 : pi-permission-system が発火する `permissions:ui_prompt` を利用する
 *
 * 備考:
 *   - 通知音スクリプトは macOS / Linux の両方に対応する。ここでは環境判定をせず
 *     detached で起動する。
 *   - pi-code などで Claude Code の hooks を併用している場合、`Notification`
 *     hook と本拡張の通知音が二重に鳴ることがある。どちらか片方を無効化する。
 */

import { spawn } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const NOTIFY_SOUND = join(homedir(), ".agents", "hooks", "notify-sound.sh");

// スクリプトを切り離して起動する。失敗しても Pi 本体を止めない (best effort)。
function run(script: string): void {
    try {
        const child = spawn("sh", [script], {
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
    pi.events.on("permissions:ui_prompt", () => {
        run(NOTIFY_SOUND);
    });
}
