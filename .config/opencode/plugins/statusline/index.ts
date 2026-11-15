import { Plugin } from "@opencode/plugin"

// サーバー側は何もしない。TUI の描画は ./tui (tui.tsx) が担当する。
export default Plugin.define({
    id: "me.statusline.server",
    setup() {},
})
