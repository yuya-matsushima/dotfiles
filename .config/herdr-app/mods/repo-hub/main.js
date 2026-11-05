import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, TextView } from "gpui-base";
import { exec, focused, nextCommand, panes, props, settings, spaces, theme, window } from "herdr";

const PR_FIELDS = "number,title,author,isDraft,reviewDecision,statusCheckRollup,updatedAt,url";
const ISSUE_FIELDS = "number,title,author,labels,comments,updatedAt,url";
const PR_DETAIL_FIELDS =
  "body,additions,deletions,changedFiles,files,baseRefName,headRefName,reviewDecision,statusCheckRollup,comments,url,state,createdAt,updatedAt";
const ISSUE_DETAIL_FIELDS = "body,state,labels,comments,url,createdAt,updatedAt";

function parseGithub(url) {
  const m = /github\.com[:/]([^/\s]+)\/([^/\s]+?)(?:\.git)?\/?$/.exec(url.trim());
  return m ? `${m[1]}/${m[2]}` : null;
}

function timeAgo(iso) {
  const then = new Date(iso).getTime();
  if (!then) return "";
  const s = Math.max(0, (Date.now() - then) / 1000);
  if (s < 60) return "now";
  if (s < 3600) return `${Math.floor(s / 60)}m`;
  if (s < 86400) return `${Math.floor(s / 3600)}h`;
  if (s < 86400 * 30) return `${Math.floor(s / 86400)}d`;
  if (s < 86400 * 365) return `${Math.floor(s / 86400 / 30)}mo`;
  return `${Math.floor(s / 86400 / 365)}y`;
}

function reviewBadge(decision) {
  switch (decision) {
    case "APPROVED":
      return { text: "APPROVED", color: "done" };
    case "CHANGES_REQUESTED":
      return { text: "CHANGES", color: "blocked" };
    case "REVIEW_REQUIRED":
      return { text: "REVIEW", color: "muted" };
    default:
      return null;
  }
}

function checkBadge(item) {
  const checks = item.statusCheckRollup ?? [];
  if (!checks.length) return null;
  let failing = 0;
  let pending = 0;
  for (const check of checks) {
    const conclusion = String(check.conclusion ?? "").toUpperCase();
    const status = String(check.status ?? "").toUpperCase();
    if (
      ["FAILURE", "TIMED_OUT", "CANCELLED", "ACTION_REQUIRED", "STARTUP_FAILURE"].includes(
        conclusion,
      )
    ) {
      failing += 1;
    } else if (!conclusion || (status && status !== "COMPLETED")) {
      pending += 1;
    }
  }
  if (failing) return { text: `${failing} failing`, color: "blocked" };
  if (pending) return { text: `${pending} pending`, color: "working" };
  return { text: "checks", color: "done" };
}

export default class RepoHub extends View {
  init(_props, cx) {
    this.tab = "pr";
    this.repo = null;
    this.root = null;
    this.prs = [];
    this.issues = [];
    this.error = null;
    this.loading = false;
    this.cwd = null;
    this.expanded = new Set();
    this.details = {};
    this.detailLoading = {};
    this.job = 0;
    this.refresh(cx);
    cx.timer.every(60000, (cx) => this.refresh(cx));
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        if (command === "refresh") {
          this.forceRefresh(cx);
          cx.notify();
        }
      }
    });
  }

  // The focused terminal's folder; when this panel has the keyboard, keep the
  // last folder that belonged to a terminal.
  currentCwd() {
    const f = focused();
    const pane = panes().find((p) => p.focused && p.cwd);
    const space = spaces().find((s) => s.active);
    return f?.cwd || pane?.cwd || space?.folder || this.cwd;
  }

  refresh(cx, force = false) {
    const cwd = this.currentCwd();
    if (!cwd) {
      this.repo = null;
      this.prs = [];
      this.issues = [];
      return;
    }
    this.cwd = cwd;
    if (this.loading && !force) return;
    const job = ++this.job;
    this.loading = true;
    this.error = null;
    cx.spawn(async (cx) => {
      try {
        const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd });
        if (top.code !== 0) throw new Error("Not a git repository");
        const root = top.stdout.trim();
        const remote = await exec("git", ["remote", "get-url", "origin"], { cwd: root });
        let repo = remote.code === 0 ? parseGithub(remote.stdout) : null;
        if (!repo) {
          const view = await exec(
            "gh",
            ["repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"],
            { cwd: root },
          );
          if (view.code === 0) repo = view.stdout.trim();
        }
        if (!repo) throw new Error("No GitHub repository for this folder");

        const [prs, issues] = await Promise.all([
          exec(
            "gh",
            ["pr", "list", "--repo", repo, "--limit", "30", "--json", PR_FIELDS],
            { cwd: root },
          ),
          exec(
            "gh",
            ["issue", "list", "--repo", repo, "--limit", "30", "--json", ISSUE_FIELDS],
            { cwd: root },
          ),
        ]);
        if (prs.code !== 0) throw new Error(prs.stderr.trim() || "gh pr list failed");
        if (issues.code !== 0) throw new Error(issues.stderr.trim() || "gh issue list failed");
        if (job !== this.job) return;

        if (this.repo !== repo) {
          this.expanded.clear();
          this.details = {};
          this.detailLoading = {};
        }
        this.repo = repo;
        this.root = root;
        this.prs = JSON.parse(prs.stdout);
        this.issues = JSON.parse(issues.stdout);
        this.error = null;
        this.reloadExpanded(cx);
      } catch (e) {
        if (job !== this.job) return;
        this.repo = null;
        this.prs = [];
        this.issues = [];
        this.error = e?.message ?? String(e);
      } finally {
        if (job === this.job) {
          this.loading = false;
          cx.notify();
        }
      }
    });
  }

  forceRefresh(cx) {
    this.details = {};
    this.detailLoading = {};
    this.refresh(cx, true);
  }

  reloadExpanded(cx) {
    for (const key of [...this.expanded]) {
      const [kind, number] = key.split(":");
      const list = kind === "pr" ? this.prs : this.issues;
      const item = list.find((x) => String(x.number) === number);
      if (!item) {
        this.expanded.delete(key);
        continue;
      }
      this.loadDetail(item, kind, cx, true);
    }
  }

  open(url) {
    const platform = window()?.platform;
    if (platform === "windows") {
      exec("cmd", ["/c", "start", "", url]).catch(() => {});
    } else {
      exec(platform === "macos" ? "open" : "xdg-open", [url]).catch(() => {});
    }
  }

  loadDetail(item, kind, cx, force = false) {
    const key = `${kind}:${item.number}`;
    if (force) {
      delete this.details[key];
      this.detailLoading[key] = false;
    } else if (this.details[key] || this.detailLoading[key]) {
      return;
    }
    const repo = this.repo;
    const root = this.root;
    if (!repo) return;
    this.detailLoading[key] = true;
    cx.spawn(async (cx) => {
      try {
        const fields = kind === "pr" ? PR_DETAIL_FIELDS : ISSUE_DETAIL_FIELDS;
        const command = kind === "pr" ? "pr" : "issue";
        const r = await exec(
          "gh",
          [command, "view", String(item.number), "--repo", repo, "--json", fields],
          { cwd: root },
        );
        if (r.code !== 0) throw new Error((r.stderr || "gh view failed").trim());
        this.details[key] = JSON.parse(r.stdout);
      } catch (e) {
        this.details[key] = { error: e?.message ?? String(e) };
      } finally {
        this.detailLoading[key] = false;
        cx.notify();
      }
    });
  }

  toggleCard(item, kind, cx) {
    const key = `${kind}:${item.number}`;
    if (this.expanded.has(key)) {
      this.expanded.delete(key);
    } else {
      this.expanded.add(key);
      this.loadDetail(item, kind, cx);
    }
    cx.notify();
  }

  detail(key, t, kind, item) {
    const data = this.details[key];
    if (this.detailLoading[key] || !data) {
      return div()
        .p(8)
        .text_size(10)
        .text_color(t.dim)
        .child("Loading details…");
    }
    if (data.error) {
      return div().p(8).text_size(10).text_color(t.blocked).child(data.error);
    }
    const body = (data.body ?? "").trim();
    const text = body;
    const files = kind === "pr" ? (data.files ?? []) : [];
    const link = (url, label) =>
      div()
        .text_size(10)
        .text_color(t.accent)
        .underline()
        .cursor_pointer()
        .hover((s) => s.text_color(t.foreground))
        .on_click((_e, cx) => {
          cx.stop_propagation();
          this.open(url);
        })
        .child(label);
    return v_flex()
      .w_full()
      .p(8)
      .gap(6)
      .border_t(1)
      .border_color(t.border)
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
      .child(
        h_flex()
          .w_full()
          .gap(8)
          .items_center()
          .text_size(10)
          .text_color(t.muted)
          .when(kind === "pr" && data.headRefName, (e) =>
            e.child(`${data.headRefName} → ${data.baseRefName}`),
          )
          .when(kind === "pr", (e) =>
            e.child(
              `+${data.additions ?? 0} −${data.deletions ?? 0} · ${
                data.changedFiles ?? 0
              } files`,
            ),
          )
          .when(kind === "issues", (e) =>
            e.child(
              `${data.state ?? ""} · ${(data.comments ?? []).length} comments`,
            ),
          )
          .child(div().flex_1())
          .child(link(data.url ?? item.url, "GitHub ↗")),
      )
      .child(
        TextView.markdown(`detail-${key}`, text || "No description.")
          .text_size(12)
          .text_color(t.foreground)
          .scrollable(false),
      )
      .when(kind === "pr" && files.length > 0, (e) =>
        e.child(
          v_flex()
            .w_full()
            .gap(4)
            .child(div().text_size(9).text_color(t.dim).child("FILES"))
            .child(
              v_flex()
                .w_full()
                .gap(2)
                .font_family(settings().font_family ?? "JetBrains Mono")
                .text_size(10)
                .children(
                  files.slice(0, 100).map((file) => {
                    const mark =
                      file.changeType === "ADDED"
                        ? "A"
                        : file.changeType === "DELETED"
                          ? "D"
                          : file.changeType === "RENAMED"
                            ? "R"
                            : file.changeType === "COPIED"
                              ? "C"
                              : "M";
                    const color =
                      mark === "A" ? t.ansi2 : mark === "D" ? t.ansi1 : t.muted;
                    return h_flex()
                      .w_full()
                      .h(18)
                      .gap(6)
                      .items_center()
                      .child(
                        div()
                          .w(10)
                          .flex_none()
                          .text_color(color)
                          .child(mark),
                      )
                      .child(
                        div()
                          .flex_1()
                          .min_w(0)
                          .truncate()
                          .text_color(t.muted)
                          .child(file.path),
                      )
                      .child(
                        div()
                          .flex_none()
                          .text_color(t.ansi2)
                          .child(`+${file.additions ?? 0}`),
                      )
                      .child(
                        div()
                          .flex_none()
                          .text_color(t.ansi1)
                          .child(`−${file.deletions ?? 0}`),
                      );
                  }),
                ),
            )
            .when(files.length > 100, (e) =>
              e.child(
                div()
                  .pt(2)
                  .text_size(9)
                  .text_color(t.dim)
                  .child(`… and ${files.length - 100} more files`),
              ),
            ),
        ),
      )
;
  }

  card(item, t, kind) {
    const key = `${kind}:${item.number}`;
    const draft = kind === "pr" && item.isDraft;
    const review = kind === "pr" ? reviewBadge(item.reviewDecision) : null;
    const checks = kind === "pr" ? checkBadge(item) : null;
    const labels = kind === "issues" ? (item.labels ?? []).slice(0, 3) : [];
    const badge = (text, color) =>
      div()
        .px(5)
        .py(1)
        .rounded(3)
        .bg(`${color}22`)
        .text_color(color)
        .text_size(9)
        .child(text);
    return v_flex()
      .id(`${kind}-${item.number}`)
      .w_full()
      .flex_none()
      .p(9)
      .gap(5)
      .rounded(8)
      .border_1()
      .border_color(t.border)
      .bg(t.surface)
      .cursor_pointer()
      .hover((s) => s.bg(t.raised).border_color(t.input))
      .on_click((_e, cx) => this.toggleCard(item, kind, cx))
      .child(
        h_flex()
          .w_full()
          .gap(6)
          .items_center()
          .child(
            div()
              .text_size(10)
              .text_color(t.accent)
              .underline()
              .cursor_pointer()
              .hover((s) => s.text_color(t.foreground))
              .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
              .on_click((_e, cx) => {
                cx.stop_propagation();
                this.open(item.url);
              })
              .child(`#${item.number}`),
          )
          .when(draft, (e) => e.child(badge("DRAFT", t.dim)))
          .when(Boolean(review), (e) =>
            e.child(badge(review.text, t[review.color] ?? t.dim)),
          )
          .child(div().flex_1())
          .child(div().text_size(10).text_color(t.dim).child(timeAgo(item.updatedAt))),
      )
      .child(div().text_size(12.5).text_color(t.foreground).child(item.title))
      .child(
        h_flex()
          .w_full()
          .gap(6)
          .items_center()
          .flex_wrap()
          .child(
            div()
              .text_size(10)
              .text_color(t.dim)
              .child(`@${item.author?.login ?? "ghost"}`),
          )
          .when(Boolean(checks), (e) =>
            e.child(
              div()
                .text_size(10)
                .text_color(t[checks.color] ?? t.dim)
                .child(checks.text),
            ),
          )
          .when(kind === "issues" && item.comments > 0, (e) =>
            e.child(
              div()
                .text_size(10)
                .text_color(t.dim)
                .child(`${item.comments} comments`),
            ),
          )
          .children(
            labels.map((label) =>
              div()
                .px(5)
                .py(1)
                .rounded(3)
                .bg(`#${label.color}22`)
                .text_color(`#${label.color}`)
                .text_size(9)
                .child(label.name),
            ),
          ),
      )
      .when(this.expanded.has(key), (e) =>
        e.child(this.detail(key, t, kind, item)),
      );
  }

  tabButton(id, icon, count, t) {
    const on = this.tab === id;
    return h_flex()
      .id(`tab-${id}`)
      .h(26)
      .px(8)
      .gap(5)
      .items_center()
      .rounded(6)
      .cursor_pointer()
      .when(on, (e) => e.bg(t.selected))
      .text_color(on ? t.foreground : t.muted)
      .hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => {
        this.tab = id;
        cx.notify();
      })
      .child(svg(icon).size(14).flex_none())
      .when(count > 0, (e) =>
        e.child(
          div()
            .text_size(9)
            .text_color(on ? t.muted : t.dim)
            .child(String(count)),
        ),
      );
  }

  render(cx) {
    const cwd = this.currentCwd();
    if (cwd && cwd !== this.cwd) {
      this.cwd = cwd;
      this.refresh(cx);
    }
    const t = theme();
    const panel = Boolean(props()?.panel);
    const items = this.tab === "pr" ? this.prs : this.issues;

    return v_flex()
      .id("repo-hub")
      .size_full()
      .min_h(0)
      .bg(panel ? t.surface : t.background)
      .when(panel, (e) =>
        e.rounded(10).border_1().border_color(t.border).overflow_hidden(),
      )
      .text_color(t.foreground)
      .text_size(12)
      .child(
        h_flex()
          .h(42)
          .flex_none()
          .px(12)
          .gap(8)
          .items_center()
          .border_b(1)
          .border_color(t.border)
          .child(div().font_semibold().child("PR / Issues"))
          .child(
            div()
              .flex_1()
              .min_w(0)
              .truncate()
              .text_size(11)
              .text_color(this.repo ? t.muted : t.dim)
              .when(Boolean(this.repo), (e) =>
                e.cursor_pointer().on_click(() =>
                  this.open(`https://github.com/${this.repo}`),
                ),
              )
              .child(this.repo ?? "No repository"),
          )
          .child(
            div()
              .id("refresh")
              .size(24)
              .flex()
              .items_center()
              .justify_center()
              .rounded(6)
              .cursor_pointer()
              .text_color(t.muted)
              .hover((s) => s.bg(t.hover))
              .on_click((_e, cx) => this.forceRefresh(cx))
              .child(this.loading ? "…" : "↻"),
          ),
      )
      .child(
        h_flex()
          .h(38)
          .flex_none()
          .px(8)
          .gap(4)
          .items_center()
          .border_b(1)
          .border_color(t.border)
          .child(this.tabButton("pr", "mods/repo-hub/icons/pull-request.svg", this.prs.length, t))
          .child(this.tabButton("issues", "mods/repo-hub/icons/issue.svg", this.issues.length, t))
          .child(div().flex_1())
          .child(
            div()
              .text_size(10)
              .text_color(t.dim)
              .child(this.loading ? "Syncing…" : "60s"),
          ),
      )
      .child(
        v_flex()
          .id("list")
          .flex_1()
          .min_h(0)
          .overflow_y_scrollbar()
          .p(8)
          .gap(8)
          .when(Boolean(this.error), (e) =>
            e.child(div().p(12).text_color(t.blocked).child(this.error)),
          )
          .when(!this.error && !this.repo && !this.loading, (e) =>
            e.child(
              div()
                .p(12)
                .text_color(t.muted)
                .child("Focus a terminal inside a GitHub repository."),
            ),
          )
          .when(!this.error && Boolean(this.repo) && !items.length && !this.loading, (e) =>
            e.child(
              div()
                .p(12)
                .text_color(t.muted)
                .child(
                  this.tab === "pr"
                    ? "No open pull requests."
                    : "No open issues.",
                ),
            ),
          )
          .children(items.map((item) => this.card(item, t, this.tab))),
      );
  }
}
