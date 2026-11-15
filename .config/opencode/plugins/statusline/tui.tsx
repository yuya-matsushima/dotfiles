/**
 * Claude Code 風のステータスラインを OpenCode V2 のプロンプトフッターに描画する TUI plugin。
 *
 * 表示: MODEL | ⚡VARIANT | IN:xx OUT:yy | 経過時間 | sub:N | CTX%
 *
 * Claude Code の statusLine (settings.json の statusLine.command) は
 * シェルコマンドの標準出力を出す仕組みだが, OpenCode には同等のキーが無い。
 * 代わりに TUI plugin の slot を利用して描画する。
 *
 * データ源:
 *   - model / variant : context.ui.model.current()
 *   - tokens          : context.data.session.get(sessionID)
 *   - context %       : 直近 assistant メッセージの tokens / Model.Info.limit.context
 *
 * agent は composer 直下の "Build · MODEL" 表示と重複するため出さない。
 */
import { Plugin, usePlugin } from "@opencode/plugin/tui"
import { Show, createMemo, createSignal, onCleanup } from "solid-js"

// gruvbox dark のパレット (theme: gruvbox)
const CYAN = "#8ec07c"
const GRAY = "#928374"
const GREEN = "#b8bb26"
const YELLOW = "#fabd2f"
const RED = "#fb4934"
const BASE = "#ebdbb2"

// 再計算のきっかけにするイベント。text delta 系は無視して頻繁な再描画を避ける。
const REFRESH_EVENTS = [
    "session.step.ended",
    "session.usage.updated",
    "session.usage.recorded",
    "session.model.selected",
    "session.agent.selected",
    "session.compaction.ended",
    "session.idle",
    "session.execution.started",
    "session.execution.succeeded",
    "session.execution.failed",
    "session.execution.interrupted",
    "session.created",
    "session.deleted",
    "model.updated",
]

function formatTokens(value: number | undefined): string {
    const n = value ?? 0
    if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`
    if (n >= 1_000) return `${(n / 1_000).toFixed(1)}k`
    return String(Math.round(n))
}

function formatDuration(ms: number): string {
    const total = Math.max(0, Math.floor(ms / 1000))
    const hours = Math.floor(total / 3600)
    const minutes = Math.floor((total % 3600) / 60)
    const seconds = total % 60
    if (hours > 0) return `${hours}h${String(minutes).padStart(2, "0")}m`
    if (minutes > 0) return `${minutes}m${String(seconds).padStart(2, "0")}s`
    return `${seconds}s`
}

function usageTotal(tokens: any): number {
    if (!tokens) return 0
    return (
        (tokens.input ?? 0) +
        (tokens.cache?.read ?? 0) +
        (tokens.cache?.write ?? 0) +
        (tokens.output ?? 0)
    )
}

function sessionIDOf(context: any, props: any): string | undefined {
    if (props?.sessionID) return props.sessionID
    const route = context.ui.router.current?.()
    if (route && route.type === "session" && route.sessionID) return route.sessionID
    return undefined
}

function StatusLine(props: { sessionID?: string }) {
    const context = usePlugin()
    const [tick, setTick] = createSignal(0)
    const [now, setNow] = createSignal(Date.now())

    onCleanup(
        context.data.listen(({ details }) => {
            if (REFRESH_EVENTS.includes(details.type)) setTick((n) => n + 1)
        }),
    )

    // 経過時間だけは毎秒更新する (他の集計はイベント駆動のまま)
    const timer = setInterval(() => setNow(Date.now()), 1000)
    onCleanup(() => clearInterval(timer))

    const view = createMemo(() => {
        // イベント駆動で読み直す (session data は自動では追従しない)
        tick()
        const selected = context.ui.model.current?.()
        const sessionID = sessionIDOf(context, props)
        if (!sessionID) return undefined

        let session: any
        try {
            session = context.data.session.get(sessionID)
        } catch {
            return undefined
        }
        if (!session) return undefined

        // モデル名と context window は選択中モデル → レジストリの順で解決する
        const location = context.location ?? context.data.location.default()
        const models: any[] = (() => {
            try {
                return context.data.location.model.list(location) ?? []
            } catch {
                return []
            }
        })()
        const ref = session.model
        const registered =
            selected?.limit?.context != null
                ? undefined
                : models.find(
                      (m) =>
                          (m.modelID === ref?.id || m.id === ref?.id) &&
                          (!ref?.providerID || m.providerID === ref.providerID),
                  )
        const modelName = selected?.name ?? registered?.name ?? ref?.id ?? "unknown"
        const limit = selected?.limit?.context ?? registered?.limit?.context
        const variant = selected?.variant ?? ref?.variant ?? "default"

        let used = usageTotal(session.tokens)
        try {
            const messages: any[] = context.data.session.message.list(sessionID) ?? []
            for (let i = messages.length - 1; i >= 0; i--) {
                const message = messages[i]
                if (message?.type === "assistant" && message.tokens) {
                    used = usageTotal(message.tokens)
                    break
                }
            }
        } catch {
            // メッセージが取れない場合はセッション累積 tokens を使う
        }

        // 稼働中のサブエージェント (子孫セッションのうち idle でないもの)
        let subagents = 0
        try {
            const family: any[] = context.data.session.family(sessionID) ?? []
            for (const item of family) {
                const id = typeof item === "string" ? item : item?.id
                if (!id || id === sessionID) continue
                const status = context.data.session.status(id)
                if (status && status.type !== "idle") subagents++
            }
        } catch {
            // サブエージェント情報が取れない場合は表示しない
        }

        return {
            model: modelName,
            variant,
            input: session.tokens?.input ?? 0,
            output: session.tokens?.output ?? 0,
            created: session.time?.created as number | undefined,
            subagents,
            percent: limit ? Math.round((used / limit) * 100) : undefined,
        }
    })

    return (
        <Show when={view()}>
            {(data) => (
                <box flexDirection="row" paddingLeft={2} paddingRight={2}>
                    <text fg={CYAN}>{data().model}</text>
                    <text fg={GRAY}>{" | "}</text>
                    <text fg={variantColor(data().variant)}>{`⚡${data().variant}`}</text>
                    <text fg={GRAY}>{" | "}</text>
                    <text fg={BASE}>{`IN:${formatTokens(data().input)} OUT:${formatTokens(data().output)}`}</text>
                    <text fg={GRAY}>{" | "}</text>
                    <text fg={BASE}>{formatDuration(now() - (data().created ?? now()))}</text>
                    <Show when={data().subagents > 0}>
                        <text fg={GRAY}>{" | "}</text>
                        <text fg={BASE}>{`sub:${data().subagents}`}</text>
                    </Show>
                    <text fg={GRAY}>{" | "}</text>
                    <text fg={contextColor(data().percent)}>
                        {data().percent == null ? "--" : `${data().percent}%`}
                    </text>
                </box>
            )}
        </Show>
    )
}

function variantColor(variant: string): string {
    switch (variant) {
        case "high":
            return RED
        case "medium":
            return YELLOW
        case "low":
            return GREEN
        default:
            return CYAN
    }
}

function contextColor(percent: number | undefined): string {
    if (percent == null) return GRAY
    if (percent > 80) return RED
    if (percent > 60) return YELLOW
    return GREEN
}

export default Plugin.define({
    id: "me.statusline",
    setup(context) {
        // composer の上の行に 1 行で差し込む (フル幅, フッターと重ならない)。
        // 画面最下部の app slot は sessionID が取れず描画できないため使わない。
        return context.ui.slot({
            append: "session.composer.top",
            render: (props: any) => <StatusLine sessionID={props?.sessionID} />,
        })
    },
})
