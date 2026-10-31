// OpenCode V2 adapter for hiroppy/tmux-agent-sidebar.
//
// Upstream ships a V1 plugin (a factory that returns the old hook object) and
// OpenCode V2 ignores that entrypoint, so loading it directly fails with
// `Plugin must export a default definition with an id and an effect or setup
// function`. This file keeps the implementation upstream and translates the
// V1 hooks to the V2 API:
//
//   chat.message       -> ctx.session.hook("prompt")
//   event              -> ctx.event.subscribe()
//   tool.execute.after -> ctx.tool.hook("execute.after")
//
// The upstream checkout lives in ~/.tmux/plugins/tmux-agent-sidebar (cloned by
// `make tmux_plugin`); this adapter does not depend on the symlink that older
// versions of that script created.

import { TmuxAgentSidebar } from "../../../.tmux/plugins/tmux-agent-sidebar/.opencode/plugins/tmux-agent-sidebar.js";

const errorMessage = (err) => {
    if (!err) return "";
    if (typeof err === "string") return err;
    if (typeof err === "object") {
        return err.message || err.name || JSON.stringify(err);
    }
    return String(err);
};

export default {
    id: "tmux-agent-sidebar",

    async setup(ctx) {
        const directory =
            typeof ctx.location?.directory === "string"
                ? ctx.location.directory
                : "";
        const hooks = await TmuxAgentSidebar({ directory });

        await ctx.session.hook("prompt", (event) => {
            const sessionID =
                typeof event.sessionID === "string" ? event.sessionID : "";
            const text =
                typeof event.prompt?.text === "string" ? event.prompt.text : "";
            return hooks["chat.message"]({ sessionID }, {
                parts: text ? [{ type: "text", text }] : [],
            });
        });

        const controller = new AbortController();
        void (async () => {
            try {
                for await (const event of ctx.event.subscribe({
                    signal: controller.signal,
                })) {
                    await hooks.event({ event });
                }
            } catch {
                // Subscription is aborted when the plugin unloads.
            }
        })();

        await ctx.tool.hook("execute.after", (event) => {
            const completed = event.status === "completed" ? event.result : undefined;
            const failed = event.status === "error" ? event.error : undefined;
            return hooks["tool.execute.after"](
                {
                    sessionID: event.sessionID ?? "",
                    tool: event.tool ?? "",
                    args: event.input ?? {},
                },
                {
                    title: completed?.title ?? "",
                    output:
                        completed?.output ??
                        (failed ? errorMessage(failed) : ""),
                    metadata: completed?.metadata ?? null,
                },
            );
        });

        return () => controller.abort();
    },
};
