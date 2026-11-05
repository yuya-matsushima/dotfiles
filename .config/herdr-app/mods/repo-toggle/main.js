import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { layout, nextCommand, run, theme } from "herdr";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

function panelState() {
  const root = layout();
  const panel = find(root, "panel");
  const body = find(root, "panel-body");
  return {
    panel,
    body,
    shown: Boolean(panel && !panel.hidden) && body?.active === "repo-hub",
  };
}

export default class RepoToggle extends View {
  init(_props, cx) {
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        if (command === "toggle") {
          this.toggle();
          cx.notify();
        }
      }
    });
  }

  toggle() {
    const { panel, body, shown } = panelState();
    if (!panel || !body) return;
    if (shown) {
      run("layout.hide", { id: "panel" });
    } else {
      run("layout.select", { stack: "panel-body", child: "repo-hub" });
      run("layout.show", { id: "panel" });
      run("repo-hub.refresh");
    }
  }

  render() {
    const t = theme();
    const { shown } = panelState();
    return h_flex()
      .size_full()
      .items_center()
      .justify_center()
      .bg(t.chrome)
      .border_b(1)
      .border_color(t.border)
      .child(
        div()
          .id("repo-toggle")
          .h(26)
          .px(8)
          .flex()
          .items_center()
          .gap(5)
          .rounded(6)
          .bg(shown ? t.selected : t.chrome)
          .text_color(shown ? t.foreground : t.muted)
          .hover((s) => s.bg(t.hover).text_color(t.foreground))
          .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
          .on_click(() => this.toggle())
          .child(svg("mods/workspace-chrome/sidebar.svg").size(14))
          .child(div().text_size(12).child("PR")),
      );
  }
}
