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
 */

import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const VERDICT_SCRIPT = join(
    homedir(),
    ".agents",
    "hooks",
    "force-push-verdict.sh",
);

const REASONS: Record<string, string> = {
    combined:
        "raw --force と --force-with-lease の併記は意図が矛盾するためブロックします。--force-with-lease 単独に絞ってください。",
    raw: "`git push --force` (or -f / -uf など短縮結合形) はブロックします。--force-with-lease を使うか, rebase + PR review を経由してください。",
    mirror:
        "`git push --mirror` は全 ref を上書きするためブロックします。個別 branch を明示して push してください。",
    plus: "`+<refspec>` による強制更新はブロックします。lease 付きで push するか, rebase + PR review を経由してください。",
};

export default function (pi: ExtensionAPI) {
    pi.on("tool_call", async (event) => {
        if (event.toolName !== "bash") return undefined;

        const command = event.input.command as string | undefined;
        if (!command) return undefined;
        if (!existsSync(VERDICT_SCRIPT)) return undefined;

        const result = spawnSync("sh", [VERDICT_SCRIPT], {
            input: command,
            encoding: "utf8",
        });
        const verdict = (result.stdout ?? "").trim();
        if (!verdict) return undefined;

        return {
            block: true,
            reason: `guard-force-push: ${REASONS[verdict] ?? verdict}`,
        };
    });
}
