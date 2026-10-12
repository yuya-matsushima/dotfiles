/**
 * guard-force-push.ts
 *
 * Pi の bash tool で `git push --force` / `git push -f` 相当をブロックする。
 *
 * 目的:
 *   Claude Code (`~/.claude/hooks/guard-force-push.sh`) と Codex
 *   (`~/.codex/hooks/guard-force-push.sh`) が共用する判定ロジック
 *   `~/.agents/hooks/force-push-verdict.sh` をそのまま再利用し、3 エージェントで
 *   同一の意味論 (subcommand 分割・クォート内区切りの無害化・push 以降の
 *   トークン単位判定) を共有する。
 *   理由文言も共通スクリプト `~/.agents/hooks/force-push-reason.sh` から取得し、
 *   本ファイルには文言をコピーしない (ドリフト防止)。
 *   pi-permission-system のパターンマッチは `git -c ... push --force` のような
 *   接頭 flag 付きの形を素通しする隙間があるため、意味論ベースの防波堤を
 *   ここに置く (両者は defense-in-depth として併用する)。
 *
 * ブロックする verdict (詳細は force-push-verdict.sh 参照):
 *   combined / raw / mirror / plus
 *   `--force-with-lease` 単独・通常の push は素通しする。
 *
 * 挙動:
 *   - verdict があれば tool_call を block する (理由を添えて LLM に返す)
 *   - 共通判定スクリプトが無い場合は fail-open (素通し)
 *   - 文言スクリプトが無い場合は verdict 文字列をそのまま理由にする
 */

import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const HOOKS_DIR = join(homedir(), ".agents", "hooks");
const VERDICT_SCRIPT = join(HOOKS_DIR, "force-push-verdict.sh");
const REASON_SCRIPT = join(HOOKS_DIR, "force-push-reason.sh");

export default function (pi: ExtensionAPI) {
    pi.on("tool_call", async (event) => {
        if (event.toolName !== "bash") return undefined;

        const command = event.input.command as string | undefined;
        if (!command) return undefined;
        if (!existsSync(VERDICT_SCRIPT)) return undefined;

        const verdictResult = spawnSync("sh", [VERDICT_SCRIPT], {
            input: command,
            encoding: "utf8",
        });
        const verdict = (verdictResult.stdout ?? "").trim();
        if (!verdict) return undefined;

        let reason = verdict;
        if (existsSync(REASON_SCRIPT)) {
            const reasonResult = spawnSync("sh", [REASON_SCRIPT, verdict], {
                encoding: "utf8",
            });
            const shared = (reasonResult.stdout ?? "").trim();
            if (shared) reason = shared;
        }

        return {
            block: true,
            reason: `guard-force-push: ${reason}`,
        };
    });
}
