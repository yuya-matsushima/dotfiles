// lazygit in a popup: ctrl-e g runs `lazygit` in the focused folder and shows
// it in a centered dialog (title bar + live terminal). The same key again
// closes it; q in lazygit ends it and the dialog goes with it. The terminal is
// one hc started without herdr labels, so it stays out of the space's tabs.

import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { hc, theme, props, closeOverlay, openOverlay, notify, focused, spaces, terminals, home, shared, setShared } from "herdr";

const STATE = "lazygit.popup";
const BAR = 28;

function folderHere() {
  return focused()?.cwd ?? spaces().find((s) => s.active)?.folder ?? home();
}

function liveTerminal(address) {
  return terminals().find((t) => t.address === address && t.state === "live") ?? null;
}

function baseName(path) {
  const parts = String(path ?? "").split(/[\\/]/).filter(Boolean);
  return parts[parts.length - 1] ?? String(path ?? "");
}

function terminalName(path) {
  const slug = baseName(path).toLowerCase().replace(/[^a-z0-9_-]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 18);
  return `lazygit-${slug || "repo"}-${Math.random().toString(36).slice(2, 6)}`.slice(0, 32);
}

export default class LazygitPopup extends View {
  init(_props, cx) {
    const p = props() ?? {};

    // The dialog's title bar: no start, only the terminal it can end.
    if (p.part === "bar") {
      this.terminal = p.terminal;
      this.folder = p.folder ?? "";
      return;
    }

    this.overlay = p.overlay;
    this.folder = folderHere();

    // Mounted anywhere but an overlay (`herdr-app check`, a layout block): do nothing.
    if (!this.overlay) return;
    this.started = null;
    this.handedOff = false;
    this.cancelled = false;

    // Already open for this folder: close it instead of starting another.
    const kept = shared(STATE);
    const running = kept?.terminal ? liveTerminal(kept.terminal) : null;
    if (running && kept?.overlay) {
      if (running.cwd === this.folder) {
        this.handedOff = true;
        this.closeSelf();
        try { closeOverlay(kept.overlay); } catch {}
        return;
      }
      try { closeOverlay(kept.overlay); } catch {}
    }

    cx.spawn(async (cx) => { await this.start(cx); });
  }

  closeSelf() {
    if (this.overlay) closeOverlay(this.overlay);
  }

  async start(cx) {
    let address = null;
    try {
      const r = await hc(["run", "--bg", "--json", "--no-parent", "--no-notify",
        "--name", terminalName(this.folder), "--cwd", this.folder, "--", "lazygit"]);
      address = r?.code === 0 ? JSON.parse(r.stdout).address : null;
      if (!address) throw new Error(r?.stderr?.trim() || "hc run failed");
    } catch (e) {
      this.closeSelf();
      notify({ title: "lazygit", body: `Couldn't start it: ${e?.message ?? e}`, level: "error", timeout: 5000 });
      return;
    }

    this.started = address;
    if (this.cancelled) {
      try { await hc(["kill", address]); } catch {}
      return;
    }
    const overlay = openOverlay({
      kind: "dialog",
      width: 0.86,
      height: 0.8,
      layout: {
        type: "column",
        children: [
          { type: "block", size: { px: BAR }, content: { mod: "lazygit-popup", props: { part: "bar", terminal: address, folder: this.folder } } },
          { type: "block", content: { terminal: address } },
        ],
      },
    });

    // The bar's close() keeps this terminal's lifetime: once the dialog owns
    // it, this copy must not kill it on its way out.
    this.handedOff = true;
    setShared(STATE, { terminal: address, overlay, folder: this.folder });
    this.closeSelf();
  }

  render(cx) {
    const t = theme();
    if ((props() ?? {}).part === "bar") return this.bar(t);
    return div().size_full().flex().items_center().justify_center().bg(t.surface)
      .text_size(12.5).text_color(t.muted).child("Opening lazygit…");
  }

  bar(t) {
    return h_flex()
      .size_full()
      .px(12)
      .gap(8)
      .items_center()
      .bg(t.chrome)
      .border_b(1)
      .border_color(t.border)
      .text_size(12.5)
      .text_color(t.muted)
      .child(svg("mods/lazygit-popup/git.svg").size(14))
      .child(div().flex_1().truncate().child(`lazygit — ${baseName(this.folder)}`))
      .child(
        div()
          .id("lazygit-popup-close")
          .w(22)
          .h(22)
          .rounded(6)
          .flex()
          .items_center()
          .justify_center()
          .cursor_pointer()
          .hover((s) => s.bg(t.hover))
          .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
          .on_click(() => closeOverlay(props().overlay))
          .child(svg("mods/lazygit-popup/x.svg").size(11)),
      );
  }

  async close(cx) {
    // The opener handed its terminal to the dialog; it must outlive that copy.
    if (this.handedOff) return;
    this.cancelled = true;
    const address = this.started ?? this.terminal;
    if (!address) return;
    const kept = shared(STATE);
    if (kept?.terminal === address) setShared(STATE, null);
    try { await hc(["kill", address]); } catch {}
  }
}
